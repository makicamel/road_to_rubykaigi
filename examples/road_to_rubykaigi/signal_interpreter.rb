module RoadToRubykaigi
  class Walk
    attr_reader :direction, :speed_ratio

    def initialize(direction:, speed_ratio:)
      @direction = direction
      @speed_ratio = speed_ratio
    end

    def right? = direction == :right
  end

  class SignalInterpreter
    CONTINUATION_WINDOW_SECONDS = 0.2 # short window used for continuation detection to avoid tail smoothing
    CONTINUATION_TIMEOUT_SECONDS = 0.8 # time without a continuation event before declaring a stop
    SPEED_RATIO_MIN = 0.7
    SPEED_RATIO_MAX = 2.3
    # Assumed motions:
    #   - in-place running (high intensity, walk-level cadence)
    #   - forward running (moderate intensity, high cadence)
    # Forward running raises cadence; in-place running raises intensity.
    # Speed = cadence_amp + intensity_boost.
    # cadence_amp is dominant; lifts forward-run.
    # intensity_boost is supplementary; lifts in-place-run, whose cadence
    # stays near walk and so cannot be picked up by cadence_amp alone.
    CADENCE_PIVOT = 1.0     # walking reference; below passes through, above gets gain
    CADENCE_GAIN = 4.5      # cadence ratios are narrow (~1.0-1.3), so amplify aggressively
    INTENSITY_PIVOT = 1.1   # intensity must clearly exceed walking before contributing
    INTENSITY_WEIGHT = 1.6  # additive boost weight for in-place run
    SPEED_SMOOTHING_ALPHA = 0.4 # EMA weight on the newest sample; lower = smoother, laggier

    # Walk states
    STOPPED = :stopped # no walk in progress; next start flips direction
    WALKING = :walking # continuation events arriving
    PAUSED = :paused   # continuation briefly absent; next event -> WALKING (same direction), timeout -> STOPPED

    def self.process(data, &block)
      @instance ||= new
      @instance.process(data, &block)
    end

    def self.stop_walk_if_expired
      @instance ||= new
      @instance.stop_walk_if_expired
    end

    # NOTE: events may fire multiple times per tick — handlers passed to
    # the block must be safe under repeated same-tick calls (idempotent
    # or self-gated).
    def process(data)
      jump_fired, action = interpret(data)
      yield :jump if jump_fired
      yield action if action
    end

    # Catch the case where the sample stream dries up mid-walk
    # (device off, BLE buffer drained, stale-drop skipping every sample).
    # The normal PAUSED -> STOPPED transition lives inside `interpret`,
    # so it only fires while samples are flowing.
    def stop_walk_if_expired
      if walk_expired?
        stop
        true
      else
        false
      end
    end

    private

    def initialize
      @window = SignalWindow.new
      @direction = :right
      @state = STOPPED
      @has_started = false
      @last_continuation_time = nil
      @smoothed_speed_ratio = nil
      config = SignalConfig.new
      @start_threshold = config.start_threshold
      @continuation_threshold = config.continuation_threshold
      @walk_cadence = config.walk_cadence
      @walk_intensity = config.walk_intensity
      @jump_detector = JumpDetector.new(gravity: config.gravity_vector)
    end

    def interpret(data)
      return unless data.key?('x') && data.key?('y') && data.key?('z')

      buffer_sample(data)
      return unless window_full?

      @continuing = nil
      was_walking = walking?
      track_continuation
      update_speed_ratio
      update_walking_state
      @direction = data['b'] == '1' ? :left : :right

      jump_fired = jump_detected?

      action = nil
      if was_walking && !walking?
        action = :stop
      elsif walking?
        action = Walk.new(direction: @direction, speed_ratio: @smoothed_speed_ratio)
      end
      [jump_fired, action]
    end

    def buffer_sample(data)
      @window.buffer_sample([data['x'].to_f, data['y'].to_f, data['z'].to_f])
    end

    def track_continuation
      @last_continuation_time = Time.now if continuing?
    end

    # EMA-smoothed mapping of motion strength to output speed. Without
    # smoothing, small frame-to-frame bumps make the speed flicker.
    def update_speed_ratio
      instant = instantaneous_speed_ratio
      @smoothed_speed_ratio ||= instant
      @smoothed_speed_ratio = @smoothed_speed_ratio * (1 - SPEED_SMOOTHING_ALPHA) + instant * SPEED_SMOOTHING_ALPHA
    end

    def instantaneous_speed_ratio
      return 1.0 unless @walk_intensity && @walk_intensity > 0

      ratio = @window.full_motion_intensity / @walk_intensity
      if ratio < SPEED_RATIO_MIN
        SPEED_RATIO_MIN
      elsif ratio > SPEED_RATIO_MAX
        SPEED_RATIO_MAX
      else
        ratio
      end
    end

    def jump_detected?
      @jump_detector.detect(sample: @window.last_sample)
    end

    def update_walking_state
      case
      when stopped? && walk_started?           then start
      when walking? && !continuing?            then pause
      when paused?  && continuing?             then unpause
      when paused?  && continuation_timed_out? then stop
      end
    end

    def start
      # @direction = (@direction == :right ? :left : :right) if @has_started
      @has_started = true
      @state = WALKING
    end

    def window_full? = @window.full?
    def stopped? = @state == STOPPED
    def walking? = @state == WALKING
    def unpause = @state = WALKING
    def paused? = @state == PAUSED
    def pause = @state = PAUSED
    def stop = @state = STOPPED
    def continuation_timed_out?
      return false if @last_continuation_time.nil?
      (Time.now - @last_continuation_time) > CONTINUATION_TIMEOUT_SECONDS
    end

    # True when a walk is in progress but the continuation timeout has elapsed.
    # The normal PAUSED -> STOPPED transition lives inside interpret(), so it
    # only fires while samples are flowing. When the stream dries up mid-walk
    # (device off, BLE buffer drained, stale-drop skipping every sample), this
    # predicate lets the caller emit :stop on a pure tick basis instead.
    def walk_expired? = !stopped? && continuation_timed_out?

    # Start detection uses the full window so that a single noisy sample
    # cannot trigger a fake walk start.
    def walk_started? = @window.full_motion_intensity > @start_threshold

    # Short-window intensity used for continuation detection. Shorter than the
    # main window so that the signal drops quickly after motion stops, making
    # stop detection responsive. Cached per-tick: process invalidates @continuing.
    def continuing?
      return @continuing unless @continuing.nil?
      @continuing = @window.tail_motion_intensity(seconds: CONTINUATION_WINDOW_SECONDS) > @continuation_threshold
    end
  end
end
