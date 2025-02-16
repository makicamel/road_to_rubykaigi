module RoadToRubykaigi
  class Player
    attr_reader :x, :y

    DELAY = 0.6
    FRAMES = [
      [
        "╭──────╮",
        "│｡・◡・│_◢◤",
        "╰ᜊ───ᜊ─╯"
      ],
      [
        "╭──────╮",
        "│｡・◡・│_◢◤",
        "╰─∪───∪╯ "
      ],
    ]

    def move(dx, dy)
      new_x = @x + dx
      new_y = @y + dy
      @x = clamp(new_x, 2, @map_width - width)
      @y = clamp(new_y, 2, @map_height - height)
    end

    def update
      if (Time.now - @frame_last_update) >= DELAY
        @frame_index = (@frame_index + 1) % FRAMES.size
        @frame_last_update = Time.now
      end
    end

    def render(offset_x:)
      FRAMES[@frame_index].map.with_index do |line, i|
        "\e[#{@y+i};#{@x-offset_x}H" + line
      end.join
    end

    def bounding_box
      { x: @x, y: @y, width: width, height: height }
    end

    def width
      @width ||= FRAMES.first.map(&:size).max
    end

    def height
      @height ||= FRAMES.first.size
    end

    private

    def initialize(x = 10, y = 9, map_width:, map_height:)
      @x = x
      @y = y
      @map_width = map_width
      @map_height = map_height
      @frame_index = 0
      @frame_last_update = Time.now
    end

    def clamp(v, min, max)
      [[v, min].max, max].min
    end
  end
end
