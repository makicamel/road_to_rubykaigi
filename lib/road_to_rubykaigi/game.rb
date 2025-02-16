module RoadToRubykaigi
  class Game
    def run
      STDIN.raw do
        loop do
          @player.update
          @effects.update
          if collided_index = collision_index
            @effects.heart(
              @player.x + @player.width - 1,
              @player.y,
            )
            @bonuses.remove(collided_index)
          end

          puts [
            ANSI::CLEAR,
          ]+[
            @map,
            *@bonuses,
            @player,
            *@player.attacks,
            *@effects,
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
      @effects = Effects.new
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

    # @return {Intger,Nil}
    def collision_index
      p = @player.bounding_box
      @bonuses.index do |bonus|
        b = bonus.bounding_box
        !(
          p[:x] + p[:width] <= b[:x] ||
          p[:x] >= b[:x] + b[:width] ||
          p[:y] + p[:height] <= b[:y] ||
          p[:y] >= b[:y] + b[:height]
        )
      end
    end
  end
end
