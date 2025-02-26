module RoadToRubykaigi
  module Manager
    class GameManager
      GOAL_X = 650
      STATE = {
        playing: 0,
        pause: 1,
        game_over: 2,
        ending: 3,
        finished: 4,
      }
      attr_reader :fireworks

      def update
        @deadline.activate(player_x: @player.x)
        if @player.x >= GOAL_X && playing?
          game_clear
        end
      end

      def finish
        @state = STATE[:finished]
      end

      def finished?
        @state == STATE[:finished]
      end

      private

      def initialize(player, deadline)
        @player = player
        @deadline = deadline
        @fireworks = RoadToRubykaigi::Fireworks.new(self)
        @state = STATE[:playing]
      end

      def playing?
        @state == STATE[:playing]
      end

      def game_clear
        @state = STATE[:ending]
        @fireworks.shoot
      end
    end
  end
end
