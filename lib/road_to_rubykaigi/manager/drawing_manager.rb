module RoadToRubykaigi
  module Manager
    class DrawingManager
      MAP_X_START = 1
      MAP_Y_START = 2

      def draw(offset_x:)
        buffer = Array.new(@viewport_height) { Array.new(@viewport_width) { "" } }
        @layers.each do |layer|
          merge_buffer(buffer, layer, offset_x: offset_x)
        end

        ANSI.home
        ANSI.background_color
        ANSI.default_text_color
        print @game_manager.render_score_board
        @viewport_height.times do |row|
          @viewport_width.times do |col|
            unless buffer[row][col] == @preview_buffer[row][col]
              print "\e[#{row+MAP_Y_START};#{col+MAP_X_START}H" + ANSI::BACKGROUND_COLOR + ANSI::DEFAULT_TEXT_COLOR + buffer[row][col]
            end
          end
        end
        @preview_buffer = buffer.map(&:dup)
      end

      private

      def initialize(map:, attacks:, bonuses:, deadline:, effects:, enemies:, player:, game_manager:)
        @viewport_width = Map::VIEWPORT_WIDTH
        @viewport_height = Map::VIEWPORT_HEIGHT
        @preview_buffer = Array.new(@viewport_height) { Array.new(@viewport_width) { "" } }
        @game_manager = game_manager
        @layers = [
          # From bottom to top
          map, player, deadline, bonuses, enemies, attacks, effects, game_manager.fireworks,
        ]
      end

      def merge_buffer(buffer, layer, offset_x:)
        layer.build_buffer(offset_x: offset_x).each_with_index do |row, i|
          row.each_with_index do |tile, j|
            buffer[i][j] = tile unless tile == ""
          end
        end
      end
    end
  end
end
