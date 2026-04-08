require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

    WINDOW_SIZE = 5
    EXIT_WINDOW_SIZE = 2
    DIRECTION_FLIP_COOLDOWN = 5 # samples
    RUN_ENTER_THRESHOLD = 0.05
    RUN_EXIT_THRESHOLD = 0.025
    REST_THRESHOLD = RUN_EXIT_THRESHOLD

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
      @warmed_up = false
      @has_started = false
      @flip_cooldown = 0
    end

    def pick
      return if GameServer.queue.empty?

      GameServer.queue.pop(true)
    end

    def interpret(data)
      return unless %w[x y z].all? { |key| data.key?(key) }

      slide_window(data['x'].to_f, data['y'].to_f, data['z'].to_f)
      return unless window_full?
      return unless warmed_up?

      update_running_state
      @direction if @running
    end

    def slide_window(x, y, z)
      @buffer << [x, y, z]
      @buffer = @buffer.last(WINDOW_SIZE)
    end

    def update_running_state
      @flip_cooldown -= 1 if @flip_cooldown.positive?

      if @running
        if motion_intensity(@buffer.last(EXIT_WINDOW_SIZE)) < RUN_EXIT_THRESHOLD
          @running = false
          @flip_cooldown = DIRECTION_FLIP_COOLDOWN
        end
      elsif window_motion_intensity > RUN_ENTER_THRESHOLD
        if @has_started
          @direction = (@direction == :right ? :left : :right) if @flip_cooldown.zero?
        else
          @has_started = true
        end
        @running = true
      end
    end

    def window_full? = @buffer.size == WINDOW_SIZE
    def warmed_up? = @warmed_up ||= window_motion_intensity < REST_THRESHOLD

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
