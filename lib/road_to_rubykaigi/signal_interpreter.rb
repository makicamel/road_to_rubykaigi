require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

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

    Walk = Data.define(:direction, :speed_ratio) do
      def right? = direction == :right
    end

    class << self
      extend Forwardable
      def_delegators :instance, :process, :log_cue
    end

    # Drain every queued sample per tick so the pipeline rate matches the
    # sensor rate instead of being capped at frame rate. NOTE: :input events
    # may fire multiple times per tick — action handlers must be safe under
    # repeated same-tick calls (idempotent or self-gated).
    def process
      Config.signal_source.drain do |data|
        if (action = interpret(data))
          EventDispatcher.publish(:input, action)
        end
      end
      if walk_expired?
        stop
        EventDispatcher.publish(:input, :stop)
      end
    end

    def log_cue(phase, text)
      return unless ENV['SIG_LOG'] == '1'

      @sig_log_io ||= open_sig_log_io
      @sig_log_io.puts "[cue] t=#{Time.now.to_f} phase=#{phase} #{text}"
    end

    private

    def initialize
      @window = SignalWindow.new
      @direction = :right
      @state = STOPPED
      @has_started = false
      @last_continuation_time = nil
      @smoothed_speed_ratio = nil
      @start_threshold = Config.start_threshold
      @continuation_threshold = Config.continuation_threshold
      @walk_cadence = Config.walk_cadence
      @walk_intensity = Config.walk_intensity
      @jump_detector = JumpDetector.new(gravity: Config.gravity_vector)
    end

    def interpret(data)
      return unless %w[x y z].all? { |key| data.key?(key) }

      buffer_sample(data)
      return unless window_full?

      was_walking = walking?
      track_continuation
      update_speed_ratio
      update_walking_state
      log_signal

      if jump_detected?
        EventDispatcher.publish(:input, :jump)
      end
      if was_walking && !walking?
        :stop
      elsif walking?
        Walk.new(direction: @direction, speed_ratio: @smoothed_speed_ratio)
      end
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

      (@window.motion_intensity / @walk_intensity).clamp(SPEED_RATIO_MIN, SPEED_RATIO_MAX)
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
      @direction = (@direction == :right ? :left : :right) if @has_started
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
    def walk_started? = @window.full.motion_intensity > @start_threshold

    # Short-window intensity used for continuation detection. Shorter than the
    # main window so that the signal drops quickly after motion stops, making
    # stop detection responsive.
    def continuing? = @window.tail(seconds: CONTINUATION_WINDOW_SECONDS).motion_intensity > @continuation_threshold

    def log_signal
      return unless ENV['SIG_LOG'] == '1'

      @sig_log_io ||= open_sig_log_io
      full = @window.motion_intensity
      tail = @window.tail(seconds: CONTINUATION_WINDOW_SECONDS).motion_intensity
      axes = @window.axis_intensities
      sum = axes.sum
      ratio = sum.zero? ? 0.0 : axes.max / sum
      vx, vy, vz = axes.map { |value| value.round(6) }
      cadence = @window.cadence_hz.round(4)
      instant = instantaneous_speed_ratio.round(4)
      speed = @smoothed_speed_ratio.round(4)
      mag = @window.last_magnitude.round(6)
      jerk = @window.mag_jerk.round(6)
      x, y, z = @window.last_sample.map { |value| value.round(6) }
      @sig_log_io.puts "#{Time.now.to_f},#{full.round(6)},#{tail.round(6)},#{ratio.round(4)},#{vx},#{vy},#{vz},#{cadence},#{instant},#{speed},#{@state},#{mag},#{jerk},#{x},#{y},#{z}"
    end

    def open_sig_log_io
      path = File.join(File.expand_path('../../tmp', __dir__), "sig_#{Time.now.strftime('%Y%m%d_%H%M')}.log")
      file = File.open(path, 'w')
      file.sync = true
      file.puts "t,full,tail,ratio,var_x,var_y,var_z,cadence,instant,speed,state,mag,jerk,x,y,z"
      $stderr.puts "[SIG_LOG] writing to #{path}"
      file
    end
  end
end
