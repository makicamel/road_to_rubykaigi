module RoadToRubykaigi
  module Sprite
    class Player
      attr_reader :x, :y
      attr_accessor :vy

      WALK_ACCEL = 15.0
      WALK_MAX_SPEED = 20.0
      WALK_FRICTION = 1.0

      INITIAL_X = 10
      BASE_Y = 26
      BASE_HEIGHT = 3
      JUMP_INITIAL_VELOCITY = -40.0
      JUMP_GRAVITY = 80.0

      ATTACK_COOLDOWN_SECOND = 0.1
      KEY_INPUT_THRESHOLD = 0.5
      ANIMETION_FRAME_SECOND = 0.25
      STUN_SECOND = 2.0
      CROUCH_SECOND = 1.0

      RIGHT = 1
      LEFT = -1

      def right
        move(RIGHT)
      end

      def left
        move(LEFT)
      end

      def jump
        unless jumping? || crouching?
          @jumping = true
          @vy = JUMP_INITIAL_VELOCITY
          Manager::AudioManager.instance.jump
        end
      end

      def crouch
        unless jumping? || crouching?
          @crouching_until = Time.now + CROUCH_SECOND
        end
      end

      def crouching?
        @crouching_until && Time.now < @crouching_until
      end

      def can_attack!
        @attack_mode = true
      end

      def can_attack?(attacks)
        @attack_mode && attacks.remain_attack? && (Time.now - @last_attack_time >= ATTACK_COOLDOWN_SECOND)
      end

      def attack(attacks)
        attacks.add(self)
        @last_attack_time = Time.now
      end

      def attack_position
        x_position = current_direction == RIGHT ? x + width : x - 2
        y_position = crouching? ? y + 2 : y + 1
        [x_position, y_position]
      end

      def stun
        @stunned_until = Time.now + STUN_SECOND
      end

      def stunned?
        Time.now < @stunned_until
      end

      def stompable?
        @stompable
      end

      def update
        return if stunned?

        now = Time.now
        standup
        if (now - @animetion_updated_time) >= ANIMETION_FRAME_SECOND
          @walking_frame = (@walking_frame + 1) % current_character.size
          @animetion_updated_time = now
        end
        if jumping?
          @stompable = @vy.positive? || (@y == BASE_Y && @vy.zero?) # stompable also when the moment just land
          if @vy.zero?
            @jumping = false
          end
        else
          @stompable = false
        end
      end

      def fall_if_ground_is_passable(map)
        foot_y = @y + BASE_HEIGHT
        center_x = @x + width / 2.0
        if map.passable_at?(center_x, foot_y + 1)
          fall
        end
      end

      def land_unless_ground_is_passable(map)
        foot_y = @y + BASE_HEIGHT
        (x...(x + width)).each do |col|
          unless map.passable_at?(col, foot_y)
            break land(foot_y)
          end
        end
      end

      def simulate_physics
        return @coordinate_updated_time = Time.now if stunned?

        now = Time.now
        elapsed_time = now - @coordinate_updated_time
        @coordinate_updated_time = now
        if jumping?
          @vy += JUMP_GRAVITY * elapsed_time
          @y += @vy * elapsed_time
          if @y >= BASE_Y
            @y = BASE_Y
            @vy = 0
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
        relative_y = @y + (BASE_HEIGHT - height) - 1
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
        @width[@attack_mode] ||= current_character.first.map(&:size).max
      end

      def height
        @height[crouching?] ||= current_character.first.size
      end

      def current_direction
        (@vx >= 0) ? RIGHT : LEFT
      end

      private

      def initialize
        @x = INITIAL_X
        @y = BASE_Y
        @vx = 0.0
        @vy = 0.0
        @width ||= {}
        @height ||= {}
        @walking_frame = 0
        @coordinate_updated_time = Time.now
        @animetion_updated_time = Time.now
        @key_input_time = Time.now
        @jumping = false
        @crouching_until = nil
        @stompable = false
        @stunned_until = Time.now
        @attack_mode = false
        @last_attack_time = Time.now
      end

      def move(dx)
        unless current_direction == dx
          @vx = 0
        end
        @vx += WALK_ACCEL * dx
        @vx = @vx.clamp(-WALK_MAX_SPEED, WALK_MAX_SPEED)
        Manager::AudioManager.instance.walk
      end

      def fall
        unless @jumping
          @jumping = true
          @vy = 0
          @stompable = true
        end
      end

      def land(land_y)
        @y = land_y - BASE_HEIGHT
        @vy = 0
        @jumping = false
        # Not change stompable since stompable will not change from true
      end

      def standup
        if @crouching_until && Time.now > @crouching_until
          @crouching_until = nil
          # Standup with jumping
          @y -= 1
          @jumping = true
          @vy = -0.1 # Avoid 0 to keep @jumping true for 1 frame
          Manager::AudioManager.instance.jump
        end
      end

      def current_character
        posture = crouching? ? :crouching : :standup
        status = stunned? ? :stunned : :normal
        Graphics::Player.character(
          posture: posture, status: status, direction: current_direction, attack_mode: @attack_mode
        )
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
    end
  end
end
