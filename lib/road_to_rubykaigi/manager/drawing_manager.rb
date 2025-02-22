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

        print "\e[1;1H" + @score_board.render
        @viewport_height.times do |row|
          @viewport_width.times do |col|
            unless buffer[row][col] == @preview_buffer[row][col]
              print "\e[#{row+MAP_Y_START};#{col+MAP_X_START}H" + buffer[row][col]
            end
          end
        end
        @preview_buffer = buffer.map(&:dup)
      end

      private

      def initialize(score_board, background, foreground)
        @viewport_width = Map::VIEWPORT_WIDTH
        @viewport_height = Map::VIEWPORT_HEIGHT
        @preview_buffer = Array.new(@viewport_height) { Array.new(@viewport_width) { "" } }
        @score_board = score_board
        @background = background
        @foreground = foreground
        @layers = [background, *foreground.layers]
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
