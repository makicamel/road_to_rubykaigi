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

    def display
      x = 0
      direction = 1

      loop do
        ANSI.clear
        puts "\e[6;1H" + LOGO
        puts [
          PLAYER.lines.map.with_index do |line, i|
            "\e[#{i+1};#{x+OFFSET}H" + line
          end.join,
          "\e[4;1H" + "Press Space to start...",
        ]
        if $stdin.raw { $stdin.read_nonblock(1, exception: false) == " " }
          break true
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
