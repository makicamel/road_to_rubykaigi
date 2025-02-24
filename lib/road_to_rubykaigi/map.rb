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

    def clamp_position(x:, y:, width:, height:, dx:, dy:)
      clamped_x = x.clamp(2, @width - width)
      clamped_y = y.clamp(2, @height - height)

      return [clamped_x, clamped_y] if box_passable?(clamped_x, clamped_y, width, height)

      corrected_x = clamped_x
      corrected_y = clamped_y
      unless dx == 0
        while corrected_x.between?(2, @width - width)
          break x_ok = true if box_passable?(corrected_x, clamped_y, width, height)
          corrected_x += dx
        end
      end
      unless dy == 0
        while corrected_y.between?(2, @height - height)
          break y_ok = true if box_passable?(clamped_x, corrected_y, width, height)
          corrected_y += dy
        end
      end

      case
      when x_ok && y_ok
        if (corrected_x - clamped_x).abs <= (corrected_y - clamped_y).abs
          [corrected_x, clamped_y]
        else
          [clamped_x, corrected_y]
        end
      when x_ok && !y_ok
        [corrected_x, clamped_y]
      when !x_ok && y_ok
        [clamped_x, corrected_y]
      when box_passable?(corrected_x, corrected_y, width, height)
        [corrected_x, corrected_y]
      when
        [clamped_x, clamped_y]
      end
    end

    private

    def initialize
      map_data = RoadToRubykaigi::Graphics::Map.data
      mask_data = RoadToRubykaigi::Graphics::Mask.data
      @tiles = map_data.each_with_index.map do |line, row|
        line.chars.each_with_index.map do |ch, col|
          Tile.new(ch, mask: mask_data[row][col])
        end
      end
      @height = @tiles.size
      @width = @tiles.first.size
    end

    def box_passable?(x, y, width, height)
      (y...(y + height)).all? do |row|
        (x...(x + width)).all? do |col|
          @tiles[row-1][col-1].passable?
        end
      end
    end
  end

  class Layer
    attr_reader :layers

    def build_buffer(offset_x:)
      @layers.map { |layer| layer.build_buffer(offset_x: offset_x) }
    end

    private

    def initialize(player:, deadline:, bonuses:, enemies:, attacks:, effects:)
      @layers = [player, deadline, bonuses, enemies, attacks, effects]
    end
  end

  class Tile
    MASK_CHAR = "#"

    def character
      @symbol
    end

    def passable?
      @mask != MASK_CHAR
    end

    private

    def initialize(symbol, mask:)
      @symbol = symbol
      @mask = mask
    end
  end
end
