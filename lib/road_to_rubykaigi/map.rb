module RoadToRubykaigi
  class Map
    attr_reader :width, :height

    def render(offset_x: 0, view_width:)
      @tiles.map.with_index do |row, i|
        visible_row = row[offset_x, view_width] || []
        "\e[#{i+1};1H" + visible_row.map(&:render).join
      end.join
    end

    private

    def initialize
      map_data = [
        "####################################################",
        "#                                                  #",
        "#                                                  #",
        "#                                                  #",
        "#                                                  #",
        "#                                                  #",
        "#                                                  #",
        "#                                                  #",
        "#                                                  #",
        "#                                                  #",
        "#                                                  #",
        "####################################################",
      ]
      @tiles = map_data.map do |line|
        line.chars.map do |ch|
          Tile.new(ch, passable: (ch != "#"))
        end
      end
      @height = @tiles.size
      @width  = @tiles.first.size
    end
  end

  class Layer
    def add(object)
      @objects << object
    end

    def remove(object)
      @objects.delete(object)
    end

    def render(offset_x: 0)
      @objects.map { |object| object.render(offset_x: offset_x) }.join
    end

    private

    def initialize
      @objects = []
    end
  end

  class Tile
    def render
      @symbol
    end

    private

    def initialize(symbol, passable: true)
      @symbol = symbol
      @passable = passable
    end
  end
end
