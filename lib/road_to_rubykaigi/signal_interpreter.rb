require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

    WINDOW_SIZE = 5
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

    def warmed_up?
      @warmed_up ||= window_motion_intensity < REST_THRESHOLD
    end

    def slide_window(x, y, z)
      @buffer << [x, y, z]
      @buffer = @buffer.last(WINDOW_SIZE)
    end

    def window_full?
      @buffer.size == WINDOW_SIZE
    end

    def update_running_state
      now_running = window_motion_intensity > (@running ? RUN_EXIT_THRESHOLD : RUN_ENTER_THRESHOLD)

      if now_running && !@running
        if @has_started
          @direction = (@direction == :right ? :left : :right)
        else
          @has_started = true
        end
      end
      @running = now_running
    end

    # Returns how far samples in the window spread from their mean position
    # (RMS distance across all 3 axes).
    def window_motion_intensity
      Math.sqrt(axis_variance(0) + axis_variance(1) + axis_variance(2))
    end

    def axis_variance(index)
      values = @buffer.map { |sample| sample[index] }
      mean = values.sum / values.size
      values.sum { |value| (value - mean) ** 2 } / values.size
    end
  end
end
