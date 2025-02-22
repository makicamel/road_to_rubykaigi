require "forwardable"

module RoadToRubykaigi
  module Sprite
    class Attacks
      extend Forwardable
      def_delegators :@attacks, :each, :delete, :select

      def add(x, y)
        @attacks << Attack.new(x, y)
      end

      def update
        @attacks.each(&:move)
      end

      def enforce_boundary(map, offset_x:)
        @attacks.reject! do |attack|
          attack.reach_border?(map, offset_x: offset_x)
        end
      end

      def build_buffer(offset_x:)
        buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
        @attacks.each do |attack|
          bounding_box = attack.bounding_box
          relative_x = bounding_box[:x] - offset_x - 1
          relative_y = bounding_box[:y] - 1
          next if relative_x < 1
          attack.characters.each_with_index do |chara, j|
            buffer[relative_y][relative_x+j] = chara
          end
        end
        buffer
      end

      private

      def initialize
        @attacks = []
      end
    end

    class Attack
      SYMBOL = ".˖"

      def move
        @x += 1
      end

      def render(offset_x:)
        "\e[#{@y};#{@x-offset_x}H" + SYMBOL
      end

      def characters
        SYMBOL.chars
      end

      def reach_border?(map, offset_x:)
        (@x - offset_x + SYMBOL.size - 1) > Map::VIEWPORT_WIDTH ||
          (@x + SYMBOL.size) > map.width
      end

      def bounding_box
        { x: @x, y: @y, width: SYMBOL.size, height: 1 }
      end

      private

      def initialize(x, y)
        @x = x
        @y = y
      end
    end
  end
end
