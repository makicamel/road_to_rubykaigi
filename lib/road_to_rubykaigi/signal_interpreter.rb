require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

    CONTINUATION_WINDOW_SIZE = 2 # short window used for continuation detection to avoid tail smoothing
    CONTINUATION_TIMEOUT_SIZE = 8 # samples without a continuation event before declaring a stop
    DEFAULT_START_THRESHOLD = 0.025
    DEFAULT_CONTINUATION_THRESHOLD = 0.05
    SPEED_RATIO_MIN = 0.7
    SPEED_RATIO_MAX = 2.2
    MOTION_INTENSITY_RATIO_MIN = 0.7
    MOTION_INTENSITY_RATIO_MAX = 1.6
    TEMPO_RATIO_MIN = 0.8
    TEMPO_RATIO_MAX = 1.6
    # Samples between continuation events at a baseline walking cadence (~10 Hz polling).
    BASELINE_CONTINUATION_INTERVAL = 18

    # Run states
    STOPPED = :stopped # no run in progress; next start flips direction
    RUNNING = :running # continuation events arriving
    PAUSED = :paused   # continuation briefly absent; next event -> RUNNING (same direction), timeout -> STOPPED

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
      @was_continuing = false
      @last_continuation_interval = nil
      @start_threshold = Config.start_threshold || DEFAULT_START_THRESHOLD
      @continuation_threshold = Config.continuation_threshold || DEFAULT_CONTINUATION_THRESHOLD
      @walk_intensity = Config.walk_intensity
    end

    def pick
      return if GameServer.queue.empty?

      GameServer.queue.pop(true)
    end

    def interpret(data)
      return unless %w[x y z].all? { |key| data.key?(key) }

      buffer_sample(data)
      return unless window_full?

      log_signal
      was_running = running?
      update_running_state
      if was_running && !running?
        :stop
      elsif running?
        [@direction, speed_ratio]
      end
    end

    # Character speed scale: motion strength * step tempo.
    # Strength picks up small motions like in-place running, while tempo
    # distinguishes walking from running.
    def speed_ratio
      (motion_intensity_ratio * tempo_ratio).clamp(SPEED_RATIO_MIN, SPEED_RATIO_MAX)
    end

    # Current motion strength relative to the walking strength captured at calibration.
    def motion_intensity_ratio
      return 1.0 unless @walk_intensity && @walk_intensity > 0

      tail = @window.tail(CONTINUATION_WINDOW_SIZE).motion_intensity
      (tail / @walk_intensity).clamp(MOTION_INTENSITY_RATIO_MIN, MOTION_INTENSITY_RATIO_MAX)
    end

    # Current continuation interval relative to the baseline walking interval.
    def tempo_ratio
      return 1.0 unless @last_continuation_interval && @last_continuation_interval > 0

      (BASELINE_CONTINUATION_INTERVAL.to_f / @last_continuation_interval).clamp(TEMPO_RATIO_MIN, TEMPO_RATIO_MAX)
    end

    def buffer_sample(data)
      @window.buffer_sample([data['x'].to_f, data['y'].to_f, data['z'].to_f])
    end

    def update_running_state
      track_samples_since_last_continuation
      case
      when stopped? && run_started?            then start
      when running? && !continuing?            then pause
      when paused?  && continuing?             then unpause
      when paused?  && continuation_timed_out? then stop
      end
    end

    def track_samples_since_last_continuation
      if continuing?
        unless @was_continuing
          @last_continuation_interval = @samples_since_last_continuation if @samples_since_last_continuation > 0
          @was_continuing = true
        end
        @samples_since_last_continuation = 0
      else
        @was_continuing = false
        @samples_since_last_continuation += 1
      end
    end

    def start
      @direction = (@direction == :right ? :left : :right) if @has_started
      @has_started = true
      @state = RUNNING
    end

    def window_full? = @window.full?
    def stopped? = @state == STOPPED
    def running? = @state == RUNNING
    def unpause = @state = RUNNING
    def paused? = @state == PAUSED
    def pause = @state = PAUSED
    def stop = @state = STOPPED
    def continuation_timed_out? = @samples_since_last_continuation > CONTINUATION_TIMEOUT_SIZE

    # Start detection uses the full window so that a single noisy sample
    # cannot trigger a fake run start.
    def run_started? = @window.full.motion_intensity > @start_threshold

    # Short-window intensity used for continuation detection. Shorter than the
    # main window so that the signal drops quickly after motion stops, making
    # stop detection responsive.
    def continuing? = @window.tail(CONTINUATION_WINDOW_SIZE).motion_intensity > @continuation_threshold

    def log_signal
      return unless ENV['SIG_LOG'] == '1'

      unless @log_header_printed
        $stderr.puts "t,full,tail,ratio,x,y,z,amp,tempo,speed,interval,state,mag,jerk"
        @log_header_printed = true
      end

      full = @window.motion_intensity
      tail = @window.tail(CONTINUATION_WINDOW_SIZE).motion_intensity
      axes = @window.axis_intensities
      sum = axes.sum
      ratio = sum.zero? ? 0.0 : axes.max / sum
      ax, ay, az = axes.map { |value| value.round(6) }
      amp = motion_intensity_ratio.round(4)
      tempo = tempo_ratio.round(4)
      speed = speed_ratio.round(4)
      interval = @last_continuation_interval || 0
      mag = @window.last_magnitude.round(6)
      jerk = @window.mag_jerk.round(6)
      $stderr.puts "#{Time.now.to_f},#{full.round(6)},#{tail.round(6)},#{ratio.round(4)},#{ax},#{ay},#{az},#{amp},#{tempo},#{speed},#{interval},#{@state},#{mag},#{jerk}"
    end
  end
end
