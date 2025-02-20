module RoadToRubykaigi
  module Graphics
    module Player
      RIGHT = RoadToRubykaigi::Player::RIGHT
      LEFT = RoadToRubykaigi::Player::LEFT

      CHARACTERS = {
        normal: {
          RIGHT => [
            <<~SPRITE,
              ╭──────╮
              │｡・◡・│_◢◤
              ╰ᜊ───ᜊ─╯
            SPRITE
            <<~SPRITE,
              ╭──────╮
              │｡・◡・│_◢◤
              ╰─∪───∪╯
            SPRITE
          ],
          LEFT => [
            <<~SPRITE,
              ╭──────╮
              │・◡・｡│_◢◤
              ╰─ᜊ───ᜊ╯
            SPRITE
            <<~SPRITE,
              ╭──────╮
              │・◡・｡│_◢◤
              ╰∪───∪─╯
            SPRITE
          ],
        },
        stunned: {
          RIGHT => [
            <<~SPRITE,
              ╭──────╮
              │ ´×⌓× │_◢◤
              ╰─ᜊ───ᜊ╯
            SPRITE
            <<~SPRITE,
              ╭──────╮
              │ ´×⌓× │_◢◤
              ╰─∪───∪╯
            SPRITE
          ],
          LEFT => [
            <<~SPRITE,
              ╭──────╮
              │ ×⌓×` │_◢◤
              ╰─ᜊ───ᜊ╯
            SPRITE
            <<~SPRITE,
              ╭──────╮
              │ ×⌓×` │_◢◤
              ╰─∪───∪╯
            SPRITE
          ],
        },
      }

      def self.character(status, direction)
        CHARACTERS[status][direction].map { |character| character.split("\n") }
      end
    end
  end
end
