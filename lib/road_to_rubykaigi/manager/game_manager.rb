module RoadToRubykaigi
  module Manager
    class GameManager
      GOAL_X = 650
      DEMO_GOAL_X = 540
      STATE = {
        playing: 0,
        pause: 1,
        game_over: 2,
        ending: 3,
        finished: 4,
      }
      attr_reader :fireworks

      def self.goal_x
        @goal_x ||= RoadToRubykaigi.demo? ? DEMO_GOAL_X : GOAL_X
      end

      def update
        @deadline.activate(player_x: @player.x)
        @enemies.activate if player_moved?
        if @player.x >= GameManager.goal_x && playing?
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

      def initialize(player, deadline, enemies)
        @player = player
        @deadline = deadline
        @enemies = enemies
        @fireworks = RoadToRubykaigi::Fireworks.new(self)
        @state = STATE[:playing]
      end

      def player_moved?
        @player_initial_x ||= @player.x
        @player_initial_x != @player.x
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
