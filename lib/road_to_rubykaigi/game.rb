module RoadToRubykaigi
  class Game
    AUTO_MOVE_INTERVAL = 1

    def run
      last_auto_walked_time = Time.now
      last_acted_time = Time.now
      $stdin.raw do
        loop do
          RoadToRubykaigi.debug.clear
          now = Time.now
          if process_input($stdin.read_nonblock(4, exception: false))
            last_acted_time = now
          end
          if now - last_acted_time > AUTO_MOVE_INTERVAL && now - last_auto_walked_time > AUTO_MOVE_INTERVAL
            @player.walk
            last_auto_walked_time = now
          end

          @update_manager.update(offset_x: @scroll_offset_x)
          @scroll_offset_x = (@player.x - Map::VIEWPORT_WIDTH / 2).clamp(0, @background.width - Map::VIEWPORT_WIDTH).to_i
          case @collision_manager.process
          when :game_over
            game_over
          when :bonus
            @score += 1
          end
          @drawing_manager.draw(offset_x: @scroll_offset_x)

          puts RoadToRubykaigi.debug
          sleep 1.0/36
        end
      end
    end

    private

    def initialize
      @background = Map.new
      @foreground = Layer.new
      @player = Sprite::Player.new
      @bonuses = Sprite::Bonuses.new(
        map_width: @background.width,
        map_height: @background.height,
      )
      @enemies = Sprite::Enemies.new(
        map_width: @background.width,
        map_height: @background.height,
      )
      @attacks = Sprite::Attacks.new
      @effects = Sprite::Effects.new
      @deadline = Sprite::Deadline.new(@background.height)
      [@player, @deadline, @bonuses, @enemies, @attacks, @effects].each do |object|
        @foreground.add(object)
      end
      @update_manager = Manager::UpdateManager.new(@background, [@player, @deadline, @attacks, @effects])
      @collision_manager = Manager::CollisionManager.new(@player, @bonuses, @enemies, @attacks, @effects, @deadline)
      @drawing_manager = Manager::DrawingManager.new(@background, @foreground)
      @scroll_offset_x = 0
      @score = 0
    end

    def process_input(input)
      return if @player.stunned?

      up = "\e[A"
      right = "\e[C"
      left = "\e[D"
      attack = " "
      stop = %W[q \x03]

      case input
      when up
        @player.jump
      when right
        @player.right
      when left
        @player.left
      when attack
        @attacks.add(
          @player.x + @player.width,
          @player.y + 1,
        )
      when *stop
        exit
      end
    end

    def game_over
      puts ANSI::RED + "Game Over\e[0m"
      exit
    end
  end
end
