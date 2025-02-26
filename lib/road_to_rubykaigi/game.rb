module RoadToRubykaigi
  class Game
    def run
      @start_time = Time.now
      ANSI.clear
      $stdin.raw do
        loop do
          RoadToRubykaigi.debug.clear
          process_input($stdin.read_nonblock(4, exception: false))

          if @game_manager.finished?
            result_time = (Time.now - @start_time).round(2)
            print(["CLEAR!", @score_board.render.strip, "Time: #{result_time} seconds"].map.with_index do |message, i|
              ANSI::RESULT_DATA[i] + message
            end.join)
            exit
          else
            @game_manager.update
            @update_manager.update(offset_x: @scroll_offset_x)
            @scroll_offset_x = (@player.x - Map::VIEWPORT_WIDTH / 2).clamp(0, @background.width - Map::VIEWPORT_WIDTH).to_i
            case @collision_manager.process
            when :game_over
              game_over
            when :bonus
              @score_board.increment
            end
            @drawing_manager.draw(offset_x: @scroll_offset_x)
          end

          puts RoadToRubykaigi.debug
          sleep 1.0/10
        end
      end
    end

    private

    def initialize
      @background = Map.new
      @score_board = ScoreBoard.new
      @player = Sprite::Player.new
      bonuses = Sprite::Bonuses.new
      enemies = Sprite::Enemies.new
      @attacks = Sprite::Attacks.new
      effects = Sprite::Effects.new
      deadline = Sprite::Deadline.new(@background.height)

      @foreground = Layer.new(
        player: @player,
        deadline: deadline,
        bonuses: bonuses,
        enemies: enemies,
        attacks: @attacks,
        effects: effects,
      )
      @game_manager = Manager::GameManager.new(@player, deadline)
      @update_manager = Manager::UpdateManager.new(@background, @foreground, @game_manager.fireworks)
      @collision_manager = Manager::CollisionManager.new(@background, @foreground)
      @drawing_manager = Manager::DrawingManager.new(@score_board, @background, @foreground, @game_manager.fireworks)
      @scroll_offset_x = 0
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
      result_time = (Time.now - @start_time).round(2)
      print([ANSI::RED + "Game Over", ANSI::DEFAULT_TEXT_COLOR + @score_board.render.strip, "Time: #{result_time} seconds"].map.with_index do |message, i|
        ANSI::RESULT_DATA[i] + "  #{message}  "
      end.join)
      exit
    end
  end
end
