module RoadToRubykaigi
  module Sprite
    class Player
      attr_reader :x, :y
      attr_accessor :vy

      WALK_ACCEL = 15.0
      WALK_MAX_SPEED = 20.0
      WALK_FRICTION = 1.0

      BASE_Y = 26
      JUMP_INITIAL_VELOCITY = -40.0
      JUMP_GRAVITY = 80.0

      KEY_INPUT_THRESHOLD = 0.5
      ANIMETION_FRAME_SECOND = 0.5
      STUN_SECOND = 2.0

      RIGHT = 1
      LEFT = -1

      def right
        move(RIGHT)
      end

      def left
        move(LEFT)
      end

      def jump
        unless jumping?
          @jumping = true
          @vy = JUMP_INITIAL_VELOCITY
        end
      end

      def land(land_y)
        @y = land_y - height
        @vy = 0
        @jumping = false
      end

      def fall
        unless @jumping
          @jumping = true
          @vy = 0
        end
      end

      def stun
        @stunned_until = Time.now + STUN_SECOND
      end

      def stunned?
        Time.now < @stunned_until
      end

      def update
        return @coordinate_updated_time = Time.now if stunned?

        now = Time.now
        if (now - @animetion_updated_time) >= ANIMETION_FRAME_SECOND
          @walking_frame = (@walking_frame + 1) % current_character.size
          @animetion_updated_time = now
        end

        elapsed_time = now - @coordinate_updated_time
        @coordinate_updated_time = now
        if jumping?
          @vy += JUMP_GRAVITY * elapsed_time
          @y += @vy * elapsed_time
          if @y >= BASE_Y
            @y = BASE_Y
            @vy = 0
            @jumping = false
          end
        else
          if current_direction == RIGHT
            @vx -= friction * elapsed_time
            @vx = [@vx, 0].max # vx must be positive
          else
            @vx += friction * elapsed_time
            @vx = [@vx, 0].min # vx must be negative
          end
        end
        @x += @vx * elapsed_time

        @x = @x.round.to_i
        @y = @y.round.to_i
      end

      def build_buffer(offset_x:)
        buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
        relative_x = @x - offset_x - 1
        relative_y = @y - 1
        current_character[@walking_frame].each_with_index do |row, i|
          row.each_with_index do |character, j|
            buffer[relative_y+i][relative_x+j] = character
          end
        end
        buffer
      end

      def enforce_boundary(map, offset_x:)
        @x, @y = map.clamp_position(
          dx: @vx.round.clamp(-1, 1) * -1,
          dy: @vy.round.clamp(-1, 1) * -1,
          **bounding_box
        )
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

      def initialize(x = 10, y = BASE_Y)
        @x = x
        @y = y
        @vx = 0.0
        @vy = 0.0
        @walking_frame = 0
        @coordinate_updated_time = Time.now
        @animetion_updated_time = Time.now
        @key_input_time = Time.now
        @jumping = false
        @stunned_until = Time.now
      end

      def move(dx)
        unless current_direction == dx
          @vx = 0
        end
        @vx += WALK_ACCEL * dx
        @vx = @vx.clamp(-WALK_MAX_SPEED, WALK_MAX_SPEED)
      end

      def current_character
        status = stunned? ? :stunned : :normal
        Graphics::Player.character(status, current_direction)
      end

      def jumping?
        @jumping
      end

      def friction
        if (Time.now - @key_input_time) >= KEY_INPUT_THRESHOLD
          WALK_MAX_SPEED
        else
          WALK_FRICTION
        end
      end

      def current_direction
        (@vx >= 0) ? RIGHT : LEFT
      end
    end
  end
end
