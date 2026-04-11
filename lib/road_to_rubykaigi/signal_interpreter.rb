require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

    PEAK_DETECTION_WINDOW_SIZE = 2 # short window used for peak detection to avoid tail smoothing
    PEAK_TIMEOUT_SIZE = 8 # samples without a peak before declaring a stop
    DEFAULT_PEAK_THRESHOLD = 0.025

    # Run states
    STOPPED = :stopped # no run in progress; next start flips direction
    RUNNING = :running # peaks arriving
    PAUSED = :paused   # peaks briefly absent; next peak -> RUNNING (same direction), timeout -> STOPPED

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
      @samples_since_peak = 0
      @peak_threshold = Config.peak_threshold || DEFAULT_PEAK_THRESHOLD
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
        @direction
      end
    end

    def buffer_sample(data)
      @window.buffer_sample([data['x'].to_f, data['y'].to_f, data['z'].to_f])
    end

    def update_running_state
      track_samples_since_peak
      case
      when stopped? && run_started?    then start
      when running? && !peak?          then pause
      when paused?  && peak?           then unpause
      when paused?  && peak_timed_out? then stop
      end
    end

    def track_samples_since_peak
      if peak?
        @samples_since_peak = 0
      else
        @samples_since_peak += 1
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
    def peak_timed_out? = @samples_since_peak > PEAK_TIMEOUT_SIZE

    # Start detection uses the full window so that a single noisy sample
    # cannot trigger a fake run start.
    def run_started? = @window.motion_intensity > @peak_threshold

    # Short-window intensity used for peak detection. Shorter than the main
    # window so that the signal drops quickly after motion stops, making
    # stop detection responsive.
    def peak? = @window.tail(PEAK_DETECTION_WINDOW_SIZE).motion_intensity > @peak_threshold

    def log_signal
      return unless ENV['SIG_LOG'] == '1'

      full = @window.motion_intensity
      tail = @window.tail(PEAK_DETECTION_WINDOW_SIZE).motion_intensity
      axes = @window.axis_intensities
      sum = axes.sum
      ratio = sum.zero? ? 0.0 : axes.max / sum
      ax, ay, az = axes.map { |value| value.round(6) }
      $stderr.puts "[sig] t=#{Time.now.to_f} full=#{full.round(6)} tail=#{tail.round(6)} ratio=#{ratio.round(4)} x=#{ax} y=#{ay} z=#{az} state=#{@state}"
    end
  end
end
