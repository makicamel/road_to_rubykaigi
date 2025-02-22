require "forwardable"

module RoadToRubykaigi
  class Enemies
    extend Forwardable
    def_delegators :@enemies, :to_a, :find, :delete

    def build_buffer(offset_x:)
      buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
      @enemies.each do |enemy|
        bounding_box = enemy.bounding_box
        relative_x = bounding_box[:x] - offset_x - 1
        relative_y = bounding_box[:y] - 1
        enemy.characters.each_with_index do |chara, j|
          buffer[relative_y][relative_x+j] = chara
        end
      end
      buffer
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

    def bounding_box
      { x: @x, y: @y, width: width, height: height }
    end

    def characters
      (self.class::CHARACTER + "\0").chars
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
