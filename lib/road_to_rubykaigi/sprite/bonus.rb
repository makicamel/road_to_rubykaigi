require "forwardable"

module RoadToRubykaigi
  module Sprite
    class Bonuses
      extend Forwardable
      def_delegators :@bonuses, :to_a, :find, :delete

      def build_buffer(offset_x:)
        buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
        @bonuses.each do |bonus|
          bounding_box = bonus.bounding_box
          relative_x = bounding_box[:x] - offset_x - 1
          relative_y = bounding_box[:y] - 1
          next if relative_x < 1
          bonus.characters.each_with_index do |chara, j|
            buffer[relative_y][relative_x+j] = chara
          end
        end
        buffer
      end

      def update
      end

      private

      def initialize(n = 3, map_width:, map_height:)
        @bonuses = (1..n).map do
          Bonus.random(
            map_width: map_width,
            map_height: map_height,
          )
        end
      end
    end

    class Bonus < Sprite
      class << self
        def random(map_width:, map_height:)
          bonus = [Ruby, Beer, Sake].sample
          x = rand(2..(map_width - Map::VIEWPORT_WIDTH))
          y = rand(2..map_height - 1)
          bonus.new(x, y)
        end
      end

      def bounding_box
        { x: @x, y: @y, width: width, height: height }
      end

      def characters
        super { [self.class::CHARACTER] }
      end

      def width
        self.class::WIDTH
      end

      def height
        self.class::HEIGHT
      end

      private

      def initialize(x, y)
        @x = x
        @y = y
      end
    end

    class Ruby < Bonus
      CHARACTER = "💎"
      WIDTH = 2
      HEIGHT = 1
    end

    class Beer < Bonus
      CHARACTER = "🍺"
      WIDTH = 2
      HEIGHT = 1
    end

    class Sake < Bonus
      CHARACTER = "🍶"
      WIDTH = 2
      HEIGHT = 1
    end
  end
end
