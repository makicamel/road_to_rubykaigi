module RoadToRubykaigi
  class Player
    DELAY = 0.6
    FRAMES = [
      [
        "╭──────╮ ",
        "│｡・◡・│_◢◤",
        "╰ᜊ───ᜊ─╯"
      ],
      [
        "╭──────╮ ",
        "│｡・◡・│_◢◤",
        "╰─∪───∪╯ "
      ],
    ]

    def move(dx, dy, map_width, map_height)
      new_x = @x + dx
      new_y = @y + dy
      @x = clamp(new_x, 2, map_width - width)
      @y = clamp(new_y, 2, map_height - height)
    end

    def draw
      str = FRAMES[@frame_index].map.with_index do |line, i|
        "\e[#{@y+i};#{@x}H" + line
      end.join("\n")
      print str
    end

    def update_frame
      if (Time.now - @frame_last_update) >= DELAY
        @frame_index = (@frame_index + 1) % FRAMES.size
        @frame_last_update = Time.now
      end
    end

    private

    def initialize(x = 10, y = 9)
      @x = x
      @y = y
      @frame_index = 0
      @frame_last_update = Time.now
    end

    def width
      @width ||= FRAMES.first.map(&:size).max
    end

    def height
      @height ||= FRAMES.map(&:size).max
    end

    def clamp(v, min, max)
      [[v, min].max, max].min
    end
  end
end
