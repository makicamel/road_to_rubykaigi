module RoadToRubykaigi
  class Game
    def run
      @start_time = Time.now
      ANSI.clear
      last_time = Time.now
      accumulator = 0.0
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
          elsif @game_manager.game_over?
            game_over
          else
            current_time = Time.now
            accumulator += current_time - last_time
            last_time = current_time
            while accumulator >= Manager::GameManager::UPDATE_RATE
              @game_manager.update
              @physics_engine.simulate
              @update_manager.update(offset_x: @game_manager.offset_x)
              @collision_manager.process
              accumulator -= Manager::GameManager::UPDATE_RATE
            end

            @drawing_manager.draw(offset_x: @game_manager.offset_x)
          end

          puts RoadToRubykaigi.debug
          sleep Manager::GameManager::FRAME_RATE
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
      deadline = Sprite::Deadline.new

      @foreground = Layer.new(
        player: @player,
        deadline: deadline,
        bonuses: bonuses,
        enemies: enemies,
        attacks: @attacks,
        effects: effects,
      )
      @game_manager = Manager::GameManager.new(
        map: @background, deadline: deadline, enemies: enemies, player: @player
      )
      @physics_engine = Manager::PhysicsEngine.new(
        attacks: @attacks, deadline: deadline, enemies: enemies, player: @player,
      )
      @update_manager = Manager::UpdateManager.new(
        map: @background, attacks: @attacks, effects: effects, enemies: enemies, player: @player, fireworks: @game_manager.fireworks,
      )
      @collision_manager = Manager::CollisionManager.new(
        attacks: @attacks, bonuses: bonuses, deadline: deadline, enemies: enemies, player: @player,
      )
      EventHander.subscribe(
        attacks: @attacks, bonuses: bonuses, effects: effects, enemies: enemies, player: @player, game_manager: @game_manager, score_board: @score_board,
      )
      @drawing_manager = Manager::DrawingManager.new(@score_board, @background, @foreground, @game_manager.fireworks)
    end

    def process_input(input)
      actions = {
        "\e[A" => :jump,
        "\e[C" => :right,
        "\e[D" => :left,
        " " => :attack,
      }
      stop = %W[q \x03]

      case
      when actions[input]
        EventDispatcher.publish(:input, actions[input])
      when stop.include?(input)
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
