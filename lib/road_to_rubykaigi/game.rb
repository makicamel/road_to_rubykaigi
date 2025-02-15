module RoadToRubykaigi
  class Game
    def run
      loop do
        ANSI.clear
        ANSI.home
        @map.draw
        @player.draw
        @player.update_frame
        STDIN.raw {
          process_input(STDIN.read_nonblock(4, exception: false))
        }
        sleep 1.0/36
      end
    end

    private

    def initialize
      @player = Player.new
      @map = Map.new
    end

    def process_input(input)
      moves = {
        "\e[A" => [0, -1], # up
        "\e[B" => [0, 1], # down
        "\e[D" => [-1, 0], # left
        "\e[C" => [1, 0], # right
      }

      if moves[input]
        @player.move(*moves[input], @map.width, @map.height)
      elsif input == "q"
        exit
      end
    end
  end
end
