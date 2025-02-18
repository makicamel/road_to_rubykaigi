module RoadToRubykaigi
  class Player
    attr_reader :x, :y

    WALKING_DELAY_SECOND = 0.6
    JUMP_DURATION_SECOND = 0.5
    JUMP_DISTANCE_WIDTH = 6
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
      unless jumping?
        @x += dx
        @y += dy
      end
    end

    def jump
      unless jumping?
        @jumping = true
        @jump_start_time = Time.now
        @jump_start_x = @x
        @jump_start_y = @y
      end
    end

    def update
      now = Time.now
      if (now - @last_walked_time) >= WALKING_DELAY_SECOND
        @walking_frame = (@walking_frame + 1) % FRAMES.size
        @last_walked_time = now
      end

      if jumping?
        if (now - @jump_start_time) >= JUMP_DURATION_SECOND
          @jumping = false
          @x = @jump_start_x + JUMP_DISTANCE_WIDTH
          @y = @jump_start_y
        else
          f = (now - @jump_start_time) / JUMP_DURATION_SECOND
          new_x = @jump_start_x + f * JUMP_DISTANCE_WIDTH

          # radius equation:
          #   (x - center_x)^2 + (y - center_y)^2 = radius^2
          # top half radius equation:
          #   y = center_y - sqrt(radius^2 - (x - center_x)^2)
          radius = JUMP_DISTANCE_WIDTH / 2
          center_x = @jump_start_x + radius
          new_y = @jump_start_y - Math.sqrt(radius**2 - (new_x - center_x)**2)
          @x = new_x.round.to_i
          @y = new_y.round.to_i
        end
      end
    end

    def render(offset_x:)
      FRAMES[@walking_frame].map.with_index do |line, i|
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
      @attacks = []
      @walking_frame = 0
      @last_walked_time = Time.now
      @jumping = false
      @jump_start_time = nil
      @jump_start_x = nil
      @jump_start_y = nil
    end

    def jumping?
      @jumping
    end
  end
end
