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
      @x += dx
      @y += dy
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

    def enforce_boundary(map, offset_x:)
      clamped_x, clamped_y = map.clamp_position(**bounding_box)
      @x = clamped_x
      @y = clamped_y
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

    def initialize(x = 10, y = 9)
      @x = x
      @y = y
      @frame_index = 0
      @frame_last_update = Time.now
    end

    def clamp(v, min, max)
      [[v, min].max, max].min
    end
  end
end
