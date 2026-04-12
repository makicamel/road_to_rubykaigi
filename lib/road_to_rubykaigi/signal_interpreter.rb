require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

    CONTINUATION_WINDOW_SIZE = 2 # short window used for continuation detection to avoid tail smoothing
    CONTINUATION_TIMEOUT_SIZE = 8 # samples without a continuation event before declaring a stop
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

    class << self
      extend Forwardable
      def_delegators :instance, :process
    end

    def process
      data = pick
      return unless data

      if (action = interpret(data))
        EventDispatcher.publish(:input, action)
      end
    end

    private

    def initialize
      @window = SignalWindow.new
      @direction = :right
      @state = STOPPED
      @has_started = false
      @samples_since_last_continuation = 0
      @smoothed_speed_ratio = nil
      @start_threshold = Config.start_threshold
      @continuation_threshold = Config.continuation_threshold
      @walk_cadence = Config.walk_cadence
      @walk_intensity = Config.walk_intensity
    end

    def pick
      return if Config.signal_source.queue.empty?

      Config.signal_source.queue.pop(true)
    end

    def interpret(data)
      return unless %w[x y z].all? { |key| data.key?(key) }

      buffer_sample(data)
      return unless window_full?

      was_walking = walking?
      track_samples_since_last_continuation
      update_speed_ratio
      update_walking_state
      log_signal
      if was_walking && !walking?
        :stop
      elsif walking?
        [@direction, @smoothed_speed_ratio]
      end
    end

    def buffer_sample(data)
      @window.buffer_sample([data['x'].to_f, data['y'].to_f, data['z'].to_f])
    end

    def track_samples_since_last_continuation
      if continuing?
        @samples_since_last_continuation = 0
      else
        @samples_since_last_continuation += 1
      end
    end

    # EMA-smoothed mapping of motion strength to output speed. Without
    # smoothing, small frame-to-frame bumps make the speed flicker.
    def update_speed_ratio
      instant = instantaneous_speed_ratio
      @smoothed_speed_ratio ||= instant
      @smoothed_speed_ratio = @smoothed_speed_ratio * (1 - SPEED_SMOOTHING_ALPHA) + instant * SPEED_SMOOTHING_ALPHA
    end

    def instantaneous_speed_ratio
      return 1.0 unless @walk_cadence && @walk_cadence > 0 && @walk_intensity && @walk_intensity > 0

      cadence_ratio = @window.cadence_hz / @walk_cadence
      cadence_amp = cadence_ratio > CADENCE_PIVOT ? CADENCE_PIVOT + (cadence_ratio - CADENCE_PIVOT) * CADENCE_GAIN : cadence_ratio
      intensity_ratio = @window.motion_intensity / @walk_intensity
      intensity_boost = [intensity_ratio - INTENSITY_PIVOT, 0].max * INTENSITY_WEIGHT
      (cadence_amp + intensity_boost).clamp(SPEED_RATIO_MIN, SPEED_RATIO_MAX)
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
    def continuation_timed_out? = @samples_since_last_continuation > CONTINUATION_TIMEOUT_SIZE

    # Start detection uses the full window so that a single noisy sample
    # cannot trigger a fake walk start.
    def walk_started? = @window.full.motion_intensity > @start_threshold

    # Short-window intensity used for continuation detection. Shorter than the
    # main window so that the signal drops quickly after motion stops, making
    # stop detection responsive.
    def continuing? = @window.tail(CONTINUATION_WINDOW_SIZE).motion_intensity > @continuation_threshold

    def log_signal
      return unless ENV['SIG_LOG'] == '1'

      unless @log_header_printed
        $stderr.puts "t,full,tail,ratio,x,y,z,cadence,instant,speed,state,mag,jerk"
        @log_header_printed = true
      end

      full = @window.motion_intensity
      tail = @window.tail(CONTINUATION_WINDOW_SIZE).motion_intensity
      axes = @window.axis_intensities
      sum = axes.sum
      ratio = sum.zero? ? 0.0 : axes.max / sum
      ax, ay, az = axes.map { |value| value.round(6) }
      cadence = @window.cadence_hz.round(4)
      instant = instantaneous_speed_ratio.round(4)
      speed = @smoothed_speed_ratio.round(4)
      mag = @window.last_magnitude.round(6)
      jerk = @window.mag_jerk.round(6)
      $stderr.puts "#{Time.now.to_f},#{full.round(6)},#{tail.round(6)},#{ratio.round(4)},#{ax},#{ay},#{az},#{cadence},#{instant},#{speed},#{@state},#{mag},#{jerk}"
    end
  end
end
