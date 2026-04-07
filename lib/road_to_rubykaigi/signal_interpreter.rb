require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

    WINDOW_SIZE = 10
    RUN_ENTER_THRESHOLD = 0.4
    RUN_EXIT_THRESHOLD = 0.2

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
      magnitude = Math.sqrt(x * x + y * y + z * z)
      deviation = (magnitude - 1.0).abs
      @buffer << deviation
      @buffer = @buffer.last(WINDOW_SIZE)
    end

    def window_full?
      @buffer.size == WINDOW_SIZE
    end

    def update_running_state
      average = @buffer.sum / @buffer.size
      now_running = average > (@running ? RUN_EXIT_THRESHOLD : RUN_ENTER_THRESHOLD)

      if now_running && !@running
        if @has_started
          @direction = (@direction == :right ? :left : :right)
        else
          @has_started = true
        end
      end
      @running = now_running
    end
  end
end
