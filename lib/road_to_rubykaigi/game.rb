module RoadToRubykaigi
  class Game
    AUTO_MOVE_INTERVAL = 1

    def run
      last_auto_moved_time = Time.now
      last_moved_time = Time.now
      $stdin.raw do
        loop do
          RoadToRubykaigi.debug.clear
          now = Time.now
          if process_input($stdin.read_nonblock(4, exception: false))
            last_moved_time = now
          end
          if now - last_moved_time > AUTO_MOVE_INTERVAL && now - last_auto_moved_time > AUTO_MOVE_INTERVAL
            @player.move(1, 0) # right
            last_auto_moved_time = now
          end

          @scroll_offset_x = (@player.x - Map::VIEWPORT_WIDTH / 2).clamp(0, @background.width - Map::VIEWPORT_WIDTH)
          @update_manager.update(offset_x: @scroll_offset_x)
          case @collision_manager.process
          when :game_over
            game_over
          when :bonus
            @score += 1
          end

          puts [
            ANSI::CLEAR,
            @background.render(offset_x: @scroll_offset_x),
            @foreground.render(offset_x: @scroll_offset_x),
            "\e[1;#{Map::VIEWPORT_WIDTH+2}HScore: #{@score}"
          ].join

          puts RoadToRubykaigi.debug
          sleep 1.0/36
        end
      end
    end

    private

    def initialize
      @background = Map.new
      @foreground = Layer.new
      @player = Player.new
      @bonuses = Bonuses.new(
        map_width: @background.width,
        map_height: @background.height,
      )
      @attacks = Attacks.new
      @effects = Effects.new
      @deadline = Deadline.new(@background.height)
      [@player, @bonuses, @attacks, @effects, @deadline].each do |object|
        @foreground.add(object)
      end
      @update_manager = UpdateManager.new(@background, [@player, @attacks, @effects])
      @collision_manager = CollisionManager.new(@player, @bonuses, @attacks, @effects, @deadline)
      @scroll_offset_x = 0
      @score = 0
    end

    def process_input(input)
      moves = {
        "\e[A" => [0, -1], # up
        "\e[B" => [0, 1], # down
        "\e[D" => [-1, 0], # left
        "\e[C" => [1, 0], # right
      }

      if moves[input]
        @player.move(*moves[input])
      elsif input == " "
        @attacks.add(
          @player.x + @player.width,
          @player.y + 1,
        )
      elsif %W[q \x03].include?(input) # Ctrl+C
        exit
      end
    end

    def game_over
      puts ANSI::RED + "Game Over\e[0m"
      exit
    end
  end
end
