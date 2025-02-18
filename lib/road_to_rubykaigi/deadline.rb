module RoadToRubykaigi
  class Deadline
    attr_reader :x, :y, :width, :height

    def find
      yield self || nil
    end

    def render(offset_x:)
      (0...@height).map do |i|
        "\e[#{@y+i};#{@x}H" + ANSI::RED + "#\e[0m"
      end.join
    end

    def bounding_box
      { x: @x, y: @y, width: @width, height: @height }
    end

    private

    def initialize(map_height)
      @x = 2
      @y = 1
      @width = 1
      @height = map_height
    end
  end
end
