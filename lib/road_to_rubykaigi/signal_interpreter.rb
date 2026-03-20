module RoadToRubykaigi
  class SignalInterpreter
    class << self
      def process
        data = pick
        return unless data

        action = interpret(data)
        EventDispatcher.publish(:input, action) if action
      end

      private

      def pick
        return if SignalServer.queue.empty?

        SignalServer.queue.pop(true)
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
end
