module RoadToRubykaigi
  class Game
    def run
      $stdin.raw do
        loop do
          RoadToRubykaigi.debug.clear

          @scroll_offset_x = [@player.x - (Map::VIEWPORT_WIDTH / 2), 0].max
          @update_manager.update(offset_x: @scroll_offset_x)
          @collision_manager.process

          puts [
            ANSI::CLEAR,
            @background.render(offset_x: @scroll_offset_x),
            @foreground.render(offset_x: @scroll_offset_x),
          ].join

          process_input($stdin.read_nonblock(4, exception: false))

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
      [@player, @bonuses, @attacks, @effects].each do |object|
        @foreground.add(object)
      end
      @update_manager = UpdateManager.new(@background, [@player, @attacks, @effects])
      @collision_manager = CollisionManager.new(@player, @bonuses, @attacks, @effects)
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
        @attacks.add(
          @player.x + @player.width,
          @player.y + 1,
        )
      elsif %W[q \x03].include?(input) # Ctrl+C
        exit
      end
    end
  end
end
