require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

    WINDOW_SIZE = 5
    PEAK_DETECTION_WINDOW_SIZE = 2 # short window used for peak detection to avoid tail smoothing
    PEAK_TIMEOUT_SIZE = 8 # samples without a peak before declaring a stop
    PEAK_THRESHOLD = 0.025

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
      @buffer = []
      @direction = :right
      @state = STOPPED
      @has_started = false
      @samples_since_peak = 0
    end

    def pick
      return if GameServer.queue.empty?

      GameServer.queue.pop(true)
    end

    def interpret(data)
      return unless %w[x y z].all? { |key| data.key?(key) }

      slide_window(data['x'].to_f, data['y'].to_f, data['z'].to_f)
      return unless window_full?

      was_running = running?
      update_running_state
      if was_running && !running?
        :stop 
      elsif running?
        @direction
      end
    end

    def slide_window(x, y, z)
      @buffer << [x, y, z]
      @buffer = @buffer.last(WINDOW_SIZE)
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

    def window_full? = @buffer.size == WINDOW_SIZE
    def stopped? = @state == STOPPED
    def running? = @state == RUNNING
    def unpause = @state = RUNNING
    def paused? = @state == PAUSED
    def pause = @state = PAUSED
    def stop = @state = STOPPED
    def peak_timed_out? = @samples_since_peak > PEAK_TIMEOUT_SIZE

    # Start detection uses the full window so that a single noisy sample
    # cannot trigger a fake run start.
    def run_started? = motion_intensity(@buffer) > PEAK_THRESHOLD

    # Short-window intensity used for peak detection. Shorter than the main
    # window so that the signal drops quickly after motion stops, making
    # stop detection responsive.
    def peak? = motion_intensity(@buffer.last(PEAK_DETECTION_WINDOW_SIZE)) > PEAK_THRESHOLD

    # Returns how far samples in the window spread from their mean position
    # (RMS distance across all 3 axes).
    def motion_intensity(samples)
      Math.sqrt(axis_variance(samples, 0) + axis_variance(samples, 1) + axis_variance(samples, 2))
    end

    def axis_variance(samples, index)
      values = samples.map { |sample| sample[index] }
      mean = values.sum / values.size
      values.sum { |value| (value - mean) ** 2 } / values.size
    end
  end
end
