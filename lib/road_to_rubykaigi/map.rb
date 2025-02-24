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

      attempt_count = 10
      delta_x = nil
      delta_y = nil
      unless dx == 0
        (1..attempt_count).each do |i|
          attempt_x = clamped_x + i * dx
          if box_passable?(attempt_x, clamped_y, width, height)
            break delta_x = attempt_x - clamped_x
          end
        end
      end
      unless dy == 0
        (1..attempt_count).each do |i|
          attempt_y = [clamped_y + i * dy, RoadToRubykaigi::Sprite::Player::BASE_Y].min
          if box_passable?(clamped_x, attempt_y, width, height)
            break delta_y = attempt_y - clamped_y
          end
        end
      end

      case
      when delta_x && delta_y
        if delta_x.abs <= delta_y.abs
          [clamped_x + delta_x, clamped_y]
        else
          [clamped_x, clamped_y + delta_y]
        end
      when delta_x && !delta_y
        [clamped_x + delta_x, clamped_y]
      when !delta_x && delta_y
        [clamped_x, clamped_y + delta_y]
      else
        coordinates = (1..attempt_count).select do |i|
          attempt_x = clamped_x + i * dx
          attempt_y = [clamped_y + i * dy, RoadToRubykaigi::Sprite::Player::BASE_Y].min
          if box_passable?(attempt_x, attempt_y, width, height)
            break [attempt_x, attempt_y]
          end
        end
        coordinates.empty? ? [clamped_x + dx, clamped_y + dy] : coordinates
      end
    end

    def passable_at?(col, row)
      @tiles[row-1][col-1].passable?
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
          passable_at?(col, row)
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
