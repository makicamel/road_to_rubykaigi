module RoadToRubykaigi
  module Sprite
    class Deadline < Sprite
      DEADLINE_SPEED = 0.3

      attr_reader :x, :y, :width, :height

      def find
        yield self || nil
      end

      def update
        now = Time.now
        if (now - @last_update) > DEADLINE_SPEED
          @x += 1
          @last_update = now
        end
      end

      def build_buffer(offset_x:)
        buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
        relative_x = @x - offset_x - 1
        relative_y = @y - 1
        @height.times do |i|
          next if relative_x < 1
          buffer[relative_y+i][relative_x] = ANSI::RED + "#\e[0m"
        end
        buffer
      end

      def bounding_box
        { x: @x, y: @y, width: @width, height: @height }
      end

      private

      def initialize(map_height)
        @x = 2
        @y = 1
        @width = 1
        @height = map_height
        @last_update = Time.now
      end
    end
  end
end
