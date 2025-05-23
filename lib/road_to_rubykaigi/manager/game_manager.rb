module RoadToRubykaigi
  module Manager
    class GameManager
      UPDATE_RATE = 1.0 / 10
      FRAME_RATE = 1.0 / 60
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

      def offset_x
        (@player.x - Map::VIEWPORT_WIDTH / 2).clamp(0, @map.width - Map::VIEWPORT_WIDTH).to_i
      end

      def update
        @deadline.activate(player_x: @player.x)
        @enemies.activate if player_moved?
        if @player.x >= GameManager.goal_x && playing?
          EventDispatcher.publish(:ending)
        end
      end

      def increment_score
        @score_board.increment
      end

      def render_score_board
        @score_board.render_score_board
      end

      def render_result
        if game_over?
          @score_board.render_game_over_result
        else
          @score_board.render_clear_result
        end
      end

      def result?
        @state == STATE[:game_over] || @state == STATE[:finished]
      end

      def game_over
        @state = STATE[:game_over]
      end

      def game_over?
        @state == STATE[:game_over]
      end

      def ending
        @state = STATE[:ending]
        @fireworks.shoot
      end

      def finish
        @state = STATE[:finished]
      end

      private

      def initialize(map:, deadline:, enemies:, player:)
        @map = map
        @player = player
        @deadline = deadline
        @enemies = enemies
        @score_board = ScoreBoard.new
        @fireworks = RoadToRubykaigi::Fireworks.new
        @state = STATE[:playing]
      end

      def player_moved?
        @player_initial_x ||= @player.x
        @player_initial_x != @player.x
      end

      def playing?
        @state == STATE[:playing]
      end
    end
  end
end
