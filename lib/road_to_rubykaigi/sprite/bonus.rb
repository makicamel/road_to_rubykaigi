require "forwardable"

module RoadToRubykaigi
  module Sprite
    class Bonuses
      extend Forwardable
      def_delegators :@bonuses, :to_a, :find, :delete
      BONUSES_DATA = {
        Basic: [
          { x: 37, y: 23, character: :coffee },
          { x: 40, y: 23, character: :book },
          { x: 72, y: 16, character: :ruby },
          { x: 76, y: 16, character: :ruby },
          { x: 135, y: 19, character: :money },
          { x: 142, y: 19, character: :money },
          { x: 135, y: 19, character: :money },
          { x: 142, y: 19, character: :money },
          { x: 153, y: 17, character: :money },
          { x: 161, y: 17, character: :money },
          { x: 173, y: 13, character: :money },
          { x: 180, y: 13, character: :money },
          { x: 190, y: 10, character: :sushi },
          { x: 195, y: 10, character: :meat },
          { x: 200, y: 10, character: :fish },
          { x: 190, y: 10, character: :sushi },
          { x: 195, y: 10, character: :meat },
          { x: 200, y: 10, character: :fish },
          { x: 205, y: 10, character: :sushi },
          { x: 210, y: 10, character: :meat },
          { x: 215, y: 10, character: :fish },
          { x: 220, y: 10, character: :sushi },
          { x: 225, y: 10, character: :meat },
          { x: 230, y: 10, character: :fish },
          { x: 288, y: 15, character: :money },
          { x: 293, y: 13, character: :money },
          { x: 298, y: 15, character: :money },
          { x: 303, y: 13, character: :money },
          { x: 308, y: 15, character: :money },
          { x: 313, y: 13, character: :money },
          { x: 318, y: 15, character: :money },
        ],
        Alcohol: [
          { x: 147, y: 28, character: :beer },
          { x: 150, y: 28, character: :beer },
          { x: 153, y: 28, character: :beer },
        ],
        Laptop: [
          { x: 228, y: 23, character: :laptop },
        ]
      }

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

      def initialize
        @bonuses = BONUSES_DATA.map do |key, bonuses|
          bonuses.map do |bonus|
            Bonus.new(
              bonus[:x],
              bonus[:y],
              bonus[:character],
            )
          end
        end.flatten
      end
    end

    class Bonus < Sprite
      CHARACTER = {
        ruby: "💎",
        money: "💰",
        coffee: "☕️",
        book: "📚",
        sushi: "🍣",
        meat: "🍖",
        fish: "🐟",
        beer: "🍺",
        sake: "🍶",
        laptop: "💻",
      }

      def bounding_box
        { x: @x, y: @y, width: width, height: height }
      end

      def characters
        super { [CHARACTER[@character]] }
      end

      def width
        2
      end

      def height
        1
      end

      private

      def initialize(x, y, character)
        @x = x
        @y = y
        @character = character
      end
    end
  end
end
