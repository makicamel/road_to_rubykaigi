module RoadToRubykaigi
  class OpeningScreen
    WIDTH = 10
    OFFSET = 30
    DELAY = 0.75
    LOGO =<<~LOGO
      ╔═══════╗
      ║       ║
      ║       ║                                ║
      ║       ║                                ║
      ╠═════╦═╝  ╔═══════╗  ╔═══════║   ╔══════╣
      ║     ╚═╗  ║       ║  ║       ║  ╔╝      ║    ══╬══  ╔═══╗
      ║       ║  ║       ║  ║       ║  ║       ║      ║    ║   ║
      ║       ║  ╚═══════╝  ╚═══════║  ╚═══════╝      ║    ╚═══╝

      ╔═══════╗                                   ║       ║
      ║       ║                                   ║       ║
      ║       ║             ║          ║       ║  ║       ║                ╔═══════║
      ║       ║             ║          ║       ║  ║       ║             ║  ║       ║  ║
      ╠═════╦═╝  ║       ║  ╠══════╗   ║       ║  ╠═════╦═╝  ╔═══════║     ║       ║
      ║     ╚═╗  ║       ║  ║      ╚╗  ╚═══════╣  ║     ╚═╗  ║       ║  ║  ╚═══════╣  ║
      ║       ║  ║       ║  ║       ║          ║  ║       ║  ║       ║  ║          ║  ║
      ║       ║  ╚═══════║  ╚═══════╝  ════════╝  ║       ║  ╚═══════║  ║  ════════╝  ║
    LOGO
    PLAYER =<<~PLAYER
      ╭──────╮
      │｡・◡・│_◢◤
      ╰ᜊ───ᜊ─╯
    PLAYER
    VERSION_ROW = 25

    def display
      loop do
        ANSI.clear
        render
        $stdin.raw do
          if handle_input == :SELECTED
            return @version_index
          end
          move_player
          sleep Manager::GameManager::FRAME_RATE
        end
      end
    end

    private

    def initialize
      @player_x = 0
      @direction = 1
      @last_move_time = Time.now
      @version_index = 0
    end

    def render
      puts [
        "\e[6;1H",
        LOGO,
        PLAYER.lines.map.with_index do |line, i|
          "\e[#{i+1};#{@player_x+OFFSET}H" + line
        end.join,
        "\e[4;1H",
        " Press Space to start...",
      ]
      RoadToRubykaigi::VERSIONS.each_with_index do |ver, i|
        cursor = i == @version_index ? " -> " : "    "
        print "\e[#{VERSION_ROW + i};1H#{cursor}ver. #{ver}"
      end
    end

    def handle_input
      case $stdin.read_nonblock(3, exception: false)
      when ANSI::UP
        @version_index = (@version_index - 1) % RoadToRubykaigi::VERSIONS.size
      when ANSI::DOWN
        @version_index = (@version_index + 1) % RoadToRubykaigi::VERSIONS.size
      when " "
        :SELECTED
      when ANSI::ETX
        raise Interrupt
      end
    end

    def move_player
      if Time.now - @last_move_time >= DELAY
        @player_x += @direction
        if @player_x >= WIDTH || @player_x <= 0
          @direction = -@direction
        end
        @last_move_time = Time.now
      end
    end
  end
end
