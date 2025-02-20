module RoadToRubykaigi
  class Player
    attr_reader :x, :y

    WALKING_DELAY_SECOND = 0.5
    JUMP_DURATION_SECOND = 0.5
    JUMP_DISTANCE_WIDTH = 6
    STUN_DURATION = 2.0
    RIGHT = 1
    LEFT = -1
    CHARACTERS = {
      normal: {
        RIGHT => [
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
        ],
        LEFT => [
          [
            "╭──────╮",
            "│・◡・｡│_◢◤",
            "╰─ᜊ───ᜊ╯"
          ],
          [
            "╭──────╮",
            "│・◡・｡│_◢◤",
            "╰∪───∪─╯ "
          ],
        ],
      },
      stunned: {
        RIGHT => [
          [
            "╭──────╮",
            "│ ´×⌓× │_◢◤",
            "╰─ᜊ───ᜊ╯"
          ],
          [
            "╭──────╮",
            "│ ´×⌓× │_◢◤",
            "╰─∪───∪╯ "
          ],
        ],
        LEFT => [
          [
            "╭──────╮",
            "│ ×⌓×` │_◢◤",
            "╰─ᜊ───ᜊ╯"
          ],
          [
            "╭──────╮",
            "│ ×⌓×` │_◢◤",
            "╰─∪───∪╯ "
          ],
        ],
      },
    }

    def right
      move(RIGHT)
    end

    def left
      move(LEFT)
    end

    def walk
      move(current_direction)
    end

    def jump
      unless jumping?
        @jumping = true
        @jump_start_time = Time.now
        @jump_base_x = @x
        @jump_base_y = @y
        @current_jump_direction = direction
      end
    end

    def stun
      @stunned_until = Time.now + STUN_DURATION
    end

    def stunned?
      Time.now < @stunned_until
    end

    def update
      now = Time.now
      if (now - @last_walked_time) >= WALKING_DELAY_SECOND
        @walking_frame = (@walking_frame + 1) % current_character.size
        @last_walked_time = now
      end

      if jumping?
        if (now - @jump_start_time) >= JUMP_DURATION_SECOND
          @jumping = false
          @x = @jump_base_x + JUMP_DISTANCE_WIDTH * @current_jump_direction
          @y = @jump_base_y
          @current_jump_direction = RIGHT
        else
          f = (now - @jump_start_time) / JUMP_DURATION_SECOND
          new_x = @jump_base_x + f * JUMP_DISTANCE_WIDTH * @current_jump_direction
          # radius equation:
          #   (x - center_x)^2 + (y - center_y)^2 = radius^2
          # top half radius equation:
          #   y = center_y - sqrt(radius^2 - (x - center_x)^2)
          radius = JUMP_DISTANCE_WIDTH / 2
          center_x = @jump_base_x + (JUMP_DISTANCE_WIDTH * @current_jump_direction) / 2.0
          new_y = @jump_base_y - Math.sqrt(radius**2 - (new_x - center_x)**2)
          @x = new_x.round.to_i
          @y = new_y.round.to_i
        end
      end
    end

    def render(offset_x:)
      current_character[@walking_frame].map.with_index do |line, i|
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
      @width ||= current_character.first.map(&:size).max
    end

    def height
      @height ||= current_character.first.size
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
      @jump_base_x = nil
      @jump_base_y = nil
      @last_dx = RIGHT
      @current_jump_direction = RIGHT
      @stunned_until = Time.now
    end

    def move(dx)
      if jumping?
        new_direction = (dx > 0) ? RIGHT : LEFT
        unless new_direction == @current_jump_direction
          @jump_base_x = @x
          @current_jump_direction = new_direction
        end
      else
        @x += dx
      end
      @last_dx = dx
    end

    def current_character
      status = stunned? ? :stunned : :normal
      CHARACTERS[status][current_direction]
    end

    def current_direction
      jumping? ? @current_jump_direction : direction
    end

    def jumping?
      @jumping
    end

    def direction
      (@last_dx > 0) ? RIGHT : LEFT
    end
  end
end
