module RoadToRubykaigi
  class OpeningScreen
    W = 10
    OFFSET = 50
    DELAY = 0.75
    CLEAR = "\e[2J"
    AA = [
      "╭──────╮",
      "│｡・◡・│_◢◤",
      "╰ᜊ───ᜊ─╯"
    ]

    def display
      position = 0
      direction = 1

      loop do
        puts [
          CLEAR,
          AA.map.with_index do |aa, i|
            "\e[#{i+1};#{position+OFFSET}H"+aa
          end.join("\n"),
          "\e[4;1H", # y;x
          "Press Space to start...",
        ]
        if STDIN.raw { STDIN.read_nonblock(1, exception: false) == " " }
          break true
        end

        position += direction
        if position >= W || position <= 0
          direction = -direction
        end
        sleep DELAY
      end
    end
  end
end
