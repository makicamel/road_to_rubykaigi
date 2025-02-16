require "forwardable"

module RoadToRubykaigi
  class Attacks
    extend Forwardable
    def_delegators :@attacks, :each, :delete

    def add(x, y)
      @attacks << Attack.new(x, y)
    end

    def update
      @attacks.each(&:move)
    end

    def enforce_boundary(map, offset_x:)
      @attacks.reject! do |attack|
        attack.reach_border?(map, offset_x: offset_x)
      end
    end

    def render(offset_x:)
      @attacks.map do |attack|
        attack.render(offset_x: offset_x)
      end.join
    end

    private

    def initialize
      @attacks = []
    end
  end

  class Attack
    SYMBOL = ".˖"

    def move
      @x += 1
    end

    def render(offset_x:)
      "\e[#{@y};#{@x-offset_x}H" + SYMBOL
    end

    def reach_border?(map, offset_x:)
      (@x - offset_x + SYMBOL.size - 1) > Map::VIEWPORT_WIDTH ||
        (@x + SYMBOL.size) > map.width
    end

    def bounding_box
      { x: @x, y: @y, width: SYMBOL.size, height: 1 }
    end

    private

    def initialize(x, y)
      @x = x
      @y = y
    end
  end
end
