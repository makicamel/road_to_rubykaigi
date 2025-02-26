module RoadToRubykaigi
  module Manager
    class GameManager
      GOAL_X = 600
      STATE = {
        playing: 0,
        pause: 1,
        game_over: 2,
        cleared: 3,
      }
      attr_reader :fireworks

      def update
        if @player.x >= GOAL_X && playing?
          game_clear
        end
      end

      def playing?
        @state == STATE[:playing]
      end

      private

      def initialize(player)
        @player = player
        @fireworks = RoadToRubykaigi::Fireworks.new
        @state = STATE[:playing]
      end

      def game_clear
        @state = STATE[:cleared]
        @fireworks.shoot
      end
    end
  end
end
