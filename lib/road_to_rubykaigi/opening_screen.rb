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
      x = 0
      direction = 1
      version_index = 0

      loop do
        ANSI.clear
        puts [
          "\e[6;1H",
          LOGO,
          PLAYER.lines.map.with_index do |line, i|
            "\e[#{i+1};#{x+OFFSET}H" + line
          end.join,
          "\e[4;1H",
          " Press Space to start...",
        ]
        RoadToRubykaigi::VERSIONS.each_with_index do |ver, i|
          cursor = i == version_index ? " -> " : "    "
          print "\e[#{VERSION_ROW + i};1H#{cursor}ver. #{ver}"
        end

        $stdin.raw do
          input = $stdin.read_nonblock(3, exception: false)
          case input
          when ANSI::UP
            version_index = (version_index - 1) % RoadToRubykaigi::VERSIONS.size
          when ANSI::DOWN
            version_index = (version_index + 1) % RoadToRubykaigi::VERSIONS.size
          when " "
            break version_index
          when ANSI::ETX
            raise Interrupt
          end

          x += direction
          if x >= WIDTH || x <= 0
            direction = -direction
          end
          sleep DELAY
        end
      end
    end
  end
end
