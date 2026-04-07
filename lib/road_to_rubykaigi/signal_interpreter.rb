require 'singleton'

module RoadToRubykaigi
  class SignalInterpreter
    include Singleton

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

    def pick
      return if GameServer.queue.empty?

      GameServer.queue.pop(true)
    end

    def interpret(data)
      return unless %w[x y z].all? { |key| data.key?(key) }

      x = data['x'].to_f
      y = data['y'].to_f
      z = data['z'].to_f

      # TODO: implement
      case
      when y < -5 then :jump
      when y > 5 then :crouch
      when x < -3 then :left
      when x > 3 then :right
      when z < -5 then :attack
      end
    end
  end
end
