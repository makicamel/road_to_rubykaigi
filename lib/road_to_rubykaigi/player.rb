module RoadToRubykaigi
  class Player
    attr_reader :attacks

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
      update_frame
      @attacks.reject! { |attack| attack.reach_border?(@map_width) }
      @attacks.each(&:update)
    end

    def render
      FRAMES[@frame_index].map.with_index do |line, i|
        "\e[#{@y+i};#{@x}H" + line
      end.join
    end

    def attack
      @attacks << Attack.new(
        @x + width,
        @y + 1,
      )
    end

    private

    def initialize(x = 10, y = 9, map_width:, map_height:)
      @x = x
      @y = y
      @map_width = map_width
      @map_height = map_height
      @frame_index = 0
      @frame_last_update = Time.now
      @attacks = []
    end

    def width
      @width ||= FRAMES.first.map(&:size).max
    end

    def height
      @height ||= FRAMES.map(&:size).max
    end

    def update_frame
      if (Time.now - @frame_last_update) >= DELAY
        @frame_index = (@frame_index + 1) % FRAMES.size
        @frame_last_update = Time.now
      end
    end

    def clamp(v, min, max)
      [[v, min].max, max].min
    end
  end

  class Attack
    SYMBOL = ".˖"

    def update
      @x += 1
    end

    def render
      "\e[#{@y};#{@x}H" + SYMBOL
    end

    def reach_border?(max_width)
      (@x + SYMBOL.size + 1) > max_width
    end

    private

    def initialize(x, y)
      @x = x
      @y = y
    end
  end
end
