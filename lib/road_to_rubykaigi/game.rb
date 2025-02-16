module RoadToRubykaigi
  class Game
    VIEWPORT_WIDTH  = 40
    def run
      STDIN.raw do
        loop do
          @scroll_offset_x = [@player.x - (VIEWPORT_WIDTH / 2), 0].max
          @player.update
          @effects.update

          CollisionManager.new(@player, @bonuses, @player.attacks, @effects).process

          puts [
            ANSI::CLEAR,
            @background.render(offset_x: @scroll_offset_x, view_width: VIEWPORT_WIDTH),
            @foreground.render(offset_x: @scroll_offset_x),
          ].join

          process_input(STDIN.read_nonblock(4, exception: false))

          sleep 1.0/36
        end
      end
    end

    private

    def initialize
      @background = Map.new
      @foreground = Layer.new
      @player = Player.new(
        map_width: @background.width,
        map_height: @background.height,
      )
      @bonuses = Bonuses.new(
        map_width: @background.width,
        map_height: @background.height,
      )
      @effects = Effects.new
      [@player, @bonuses, @effects].each do |object|
        @foreground.add(object)
      end
      @scroll_offset_x = 0
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
