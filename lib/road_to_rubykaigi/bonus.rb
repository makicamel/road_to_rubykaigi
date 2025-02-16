module RoadToRubykaigi
  class Bonuses
    def to_a
      @bonuses.to_a
    end

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

    def render
      colored.map.with_index do |line, i|
        "\e[#{@y+i};#{@x}H" + line
      end.join
    end

    def width
      @width ||= self.class.width
    end

    def height
      @height ||= self.class.height
    end

    private

    def initialize(x, y)
      @x = x
      @y = y
    end

    def colored
      self.class::CHARACTER.map do |line|
        self.class::COLOR + line + ANSI::RESET
      end
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
