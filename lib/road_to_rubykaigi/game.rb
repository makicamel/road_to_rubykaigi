module RoadToRubykaigi
  class Game
    def run
      STDIN.raw do
        loop do
          @player.update
          puts [
            ANSI::CLEAR,
          ]+[
            @map,
            *@bonuses,
            @player,
            *@player.attacks,
          ].map(&:render)
          process_input(STDIN.read_nonblock(4, exception: false))
          sleep 1.0/36
        end
      end
    end

    private

    def initialize
      @map = Map.new
      @player = Player.new(
        map_width: @map.width,
        map_height: @map.height,
      )
      @bonuses = Bonuses.new(
        map_width: @map.width,
        map_height: @map.height,
      )
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
        @player.attack
      elsif %W[q \x03].include?(input) # Ctrl+C
        exit
      end
    end
  end
end
