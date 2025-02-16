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
        x = rand(2..(map_width - bonus.width))
        y = rand(2..(map_height - bonus.height))
        bonus.new(x, y)
      end

      def width
        self::CHARACTER.map(&:size).max
      end

      def height
        self::CHARACTER.size
      end
    end

    def bounding_box
      { x: @x, y: @y, width: self.class.width, height: self.class.height }
    end

    def render(offset_x:)
      screen_x = @x - offset_x
      position_x = [screen_x, 1].max
      self.class::CHARACTER.map.with_index do |line, i|
        visible_charas = clip(line, screen_x)
        next "" if visible_charas.empty?
        "\e[#{@y+i};#{position_x}H" + color(visible_charas)
      end.join
    end

    private

    def initialize(x, y)
      @x = x
      @y = y
    end

    def clip(line, screen_x)
      return "" if screen_x + line.size <= 1

      available_width = Map::VIEWPORT_WIDTH - ([screen_x, 1].max - 1)
      visible_start = screen_x >= 1 ? 0 : (1 - screen_x)
      visible_size = [line.size - visible_start, available_width].min
      line[visible_start, visible_size] || ""
    end

    def color(line)
      self.class::COLOR + line + ANSI::RESET
    end
  end

  class Ruby < Bonus
    CHARACTER = [
      "⣠⣤⣄",
      "⠙⣿⠋"
    ]
    COLOR = "\e[31m" # red
  end

  class Beer < Bonus
    WHITE = "\e[37m"
    CHARACTER = [
      "#{WHITE}▂▂",
      "▓▓#{WHITE}⠝",
    ]
    COLOR = "\e[33m" # yellow
  end

  class Sake < Bonus
    CHARACTER = [
      "╭▀╮",
      "╰─╯",
    ]
    COLOR = "\e[38;5;94m" # dark brown
  end
end
