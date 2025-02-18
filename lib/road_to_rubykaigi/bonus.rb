require "forwardable"

module RoadToRubykaigi
  class Bonuses
    extend Forwardable
    def_delegators :@bonuses, :to_a, :find, :delete

    def render(offset_x:)
      @bonuses.map do |bonus|
        bonus.render(offset_x: offset_x)
      end.join
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

  class Bonus
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

    def render(offset_x:)
      screen_x = @x - offset_x
      position_x = [screen_x, 1].max

      "\e[#{@y};#{position_x}H" + self.class::CHARACTER
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

    def clip(line, screen_x)
      return "" if screen_x + line.size <= 1

      available_width = Map::VIEWPORT_WIDTH - ([screen_x, 1].max - 1)
      visible_start = (screen_x >= 1) ? 0 : (1 - screen_x)
      visible_size = [line.size - visible_start, available_width].min
      line[visible_start, visible_size] || ""
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
