module RoadToRubykaigi
  class Map
    VIEWPORT_WIDTH = 100
    VIEWPORT_HEIGHT = 30
    attr_reader :width, :height

    def build_buffer(offset_x:)
      (0...VIEWPORT_HEIGHT).map do |row|
        @tiles[row][offset_x, VIEWPORT_WIDTH].map(&:character)
      end
    end

    def clamp_position(x:, y:, width:, height:)
      [
        x.clamp(2, VIEWPORT_WIDTH),
        y.clamp(2, @height - height),
      ]
    end

    private

    def initialize
      map_data = RoadToRubykaigi::Graphics::Map.data
      @tiles = map_data.map do |line|
        line.chars.map do |ch|
          Tile.new(ch, passable: (ch != "#"))
        end
      end
      @height = @tiles.size
      @width = @tiles.first.size
    end
  end

  class Layer
    attr_reader :layers

    def add(layer)
      @layers << layer
    end

    def remove(layer)
      @layers.delete(layer)
    end

    def build_buffer(offset_x:)
      @layers.map { |layer| layer.build_buffer(offset_x: offset_x) }
    end

    private

    def initialize
      @layers = []
    end
  end

  class Tile
    def character
      @symbol
    end

    private

    def initialize(symbol, passable: true)
      @symbol = symbol
      @passable = passable
    end
  end
end
