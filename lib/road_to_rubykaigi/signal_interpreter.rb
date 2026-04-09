require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

    WINDOW_SIZE = 5
    EXIT_WINDOW_SIZE = 2
    FLIP_COOLDOWN_SIZE = 5 # samples after a stop during which direction flip is suppressed
    RUN_ENTER_THRESHOLD = 0.05
    RUN_EXIT_THRESHOLD = 0.025

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
      @running = false
      @has_started = false
      @flip_cooldown_remaining = 0
    end

    def pick
      return if GameServer.queue.empty?

      GameServer.queue.pop(true)
    end

    def interpret(data)
      return unless %w[x y z].all? { |key| data.key?(key) }

      slide_window(data['x'].to_f, data['y'].to_f, data['z'].to_f)
      return unless window_full?

      update_running_state
      @direction if @running
    end

    def slide_window(x, y, z)
      @buffer << [x, y, z]
      @buffer = @buffer.last(WINDOW_SIZE)
    end

    def update_running_state
      tick_flip_cooldown
      case
      when running? && motion_stopped?
        stop
      when !running? && motion_started?
        start
      end
    end

    def stop
      @running = false
      @flip_cooldown_remaining = FLIP_COOLDOWN_SIZE
    end

    def start
      if @has_started && flip_allowed?
        @direction = (@direction == :right ? :left : :right)
      end
      @has_started = true
      @running = true
    end

    def tick_flip_cooldown
      @flip_cooldown_remaining -= 1 if @flip_cooldown_remaining.positive?
    end

    def window_full? = @buffer.size == WINDOW_SIZE
    def running? = @running
    def motion_started? = window_motion_intensity > RUN_ENTER_THRESHOLD
    def motion_stopped? = motion_intensity(@buffer.last(EXIT_WINDOW_SIZE)) < RUN_EXIT_THRESHOLD
    def flip_allowed? = @flip_cooldown_remaining.zero?

    # Returns how far samples in the window spread from their mean position
    # (RMS distance across all 3 axes).
    def window_motion_intensity = motion_intensity(@buffer)

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
