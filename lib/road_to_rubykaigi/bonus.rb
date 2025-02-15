module RoadToRubykaigi
  class Bonus
    RUBY = [
      "\e[31m⣠⣤⣄\e[0m",
      "\e[31m⠙⣿⠋\e[0m",
    ]
    BEER = [
      "\e[37m▂▂ \e[0m",
      "\e[33m▓▓\e[0m⠝",
    ]
    SAKE = [
      "\e[38;5;94m╭▀╮\e[0m",
      "\e[38;5;94m╰─╯\e[0m",
    ]

    BONUS_TYPES = [RUBY, BEER, SAKE]

    def self.random(map_width:, map_height:)
      bonus = BONUS_TYPES.sample
      bonus_width = bonus.first.gsub(/\e\[[0-9;]+m/, "").size
      bonus_height = bonus.size
      x = rand(2..(map_width - bonus_width))
      y = rand(2..(map_height - bonus_height))
      new(x, y, bonus)
    end

    def initialize(x, y, bonus)
      @x = x
      @y = y
      @bonus = bonus
    end

    def render
      @bonus.map.with_index do |line, i|
        "\e[#{@y+i};#{@x}H" + line
      end.join
    end
  end
end
