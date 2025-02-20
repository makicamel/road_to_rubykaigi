require "forwardable"

module RoadToRubykaigi
  class Enemies
    extend Forwardable
    def_delegators :@enemies, :to_a, :find, :delete

    def render(offset_x:)
      @enemies.map do |enemy|
        enemy.render(offset_x: offset_x)
      end.join
    end

    private

    def initialize(n = 3, map_width:, map_height:)
      @enemies = (1..n).map do
        Enemy.random(
          map_width: map_width,
          map_height: map_height,
        )
      end
    end
  end

  class Enemy
    attr_reader :x, :y

    def self.random(map_width:, map_height:)
      x = rand(2..(map_width - Map::VIEWPORT_WIDTH))
      y = rand(2..map_height - 1)
      Bug.new(x, y)
    end

    def render(offset_x:)
      "\e[#{@y};#{@x-offset_x}H" + character
    end

    def bounding_box
      { x: @x, y: @y, width: width, height: height }
    end

    def character
      self.class::CHARACTER
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
  end

  class Bug < Enemy
    CHARACTER = ["🐛", "🐝"].sample
    WIDTH = 2
    HEIGHT = 1
  end
end
