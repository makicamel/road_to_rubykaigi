require "forwardable"

module RoadToRubykaigi
  module Sprite
    class Bonuses
      extend Forwardable
      def_delegators :@bonuses, :to_a, :find, :delete
      BONUSES_DATA = {
        2025 => {
          Basic: [
            { x: 39, y: 22, character: :ruby },
            { x: 46, y: 22, character: :ruby },
            { x: 53, y: 22, character: :ruby },
            { x: 107, y: 23, character: :coffee },
            { x: 110, y: 23, character: :book },
            { x: 142, y: 16, character: :ruby },
            { x: 146, y: 16, character: :ruby },
            { x: 205, y: 19, character: :money },
            { x: 212, y: 19, character: :money },
            { x: 205, y: 19, character: :money },
            { x: 212, y: 19, character: :money },
            { x: 223, y: 17, character: :money },
            { x: 231, y: 17, character: :money },
            { x: 243, y: 13, character: :money },
            { x: 250, y: 13, character: :money },
            { x: 260, y: 10, character: :sushi },
            { x: 265, y: 10, character: :meat },
            { x: 270, y: 10, character: :fish },
            { x: 260, y: 10, character: :sushi },
            { x: 265, y: 10, character: :meat },
            { x: 270, y: 10, character: :fish },
            { x: 275, y: 10, character: :sushi },
            { x: 280, y: 10, character: :meat },
            { x: 285, y: 10, character: :fish },
            { x: 290, y: 10, character: :sushi },
            { x: 295, y: 10, character: :meat },
            { x: 300, y: 10, character: :fish },
            { x: 358, y: 15, character: :money },
            { x: 363, y: 13, character: :money },
            { x: 368, y: 15, character: :money },
            { x: 373, y: 13, character: :money },
            { x: 378, y: 15, character: :money },
            { x: 383, y: 13, character: :money },
            { x: 388, y: 15, character: :money },
          ],
          Alcohol: [
            { x: 217, y: 28, character: :beer },
            { x: 220, y: 28, character: :beer },
            { x: 223, y: 28, character: :beer },
          ],
          Laptop: [
            { x: 298, y: 23, character: :laptop },
          ],
        },
        2026 => {
          Basic: [],
          Alcohol: [],
          Laptop: [],
        },
      }

      def build_buffer(offset_x:)
        buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
        @bonuses.each do |bonus|
          bounding_box = bonus.bounding_box
          relative_x = bounding_box[:x] - offset_x - 1
          relative_y = bounding_box[:y] - 1
          next if relative_x < 1
          bonus.characters.each_with_index do |character, j|
            next if relative_x + j >= Map::VIEWPORT_WIDTH - 1
            buffer[relative_y][relative_x+j] = character
          end
        end
        buffer
      end

      def update
      end

      private

      def initialize
        @bonuses = BONUSES_DATA[RoadToRubykaigi.version].map do |key, bonuses|
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
      TYPE = {
        ruby: :basic,
        money: :basic,
        coffee: :basic,
        book: :basic,
        sushi: :basic,
        meat: :basic,
        fish: :basic,
        beer: :alcohol,
        sake: :alcohol,
        laptop: :laptop,
      }

      def type
        TYPE[@character]
      end

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
