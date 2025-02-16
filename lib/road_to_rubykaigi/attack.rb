module RoadToRubykaigi
  class Attacks
    extend Forwardable
    def_delegators :@attacks, :each, :delete

    def add(x, y)
      @attacks << Attack.new(x, y)
    end

    def update
      @attacks.reject! { |attack| attack.reach_border?(@map_width) }
      @attacks.each(&:update)
    end

    def render(offset_x:)
      @attacks.map do |attack|
        attack.render(offset_x: offset_x)
      end.join
    end

    private

    def initialize(map_width:)
      @map_width = map_width
      @attacks = []
    end
  end

  class Attack
    SYMBOL = ".˖"

    def update
      @x += 1
    end

    def render(offset_x:)
      "\e[#{@y};#{@x-offset_x}H" + SYMBOL
    end

    def reach_border?(max_width)
      (@x + SYMBOL.size + 1) > max_width
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
