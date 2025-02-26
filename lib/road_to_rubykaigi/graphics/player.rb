module RoadToRubykaigi
  module Graphics
    module Player
      RIGHT = RoadToRubykaigi::Sprite::Player::RIGHT
      LEFT = RoadToRubykaigi::Sprite::Player::LEFT

      CHARACTERS = {
        normal: {
          RIGHT => [
            <<~SPRITE,
              ╭──────╮
              │｡・◡・│
              ╰ᜊ───ᜊ─╯
            SPRITE
            <<~SPRITE,
              ╭──────╮
              │｡・◡・│
              ╰─∪───∪╯
            SPRITE
          ],
          LEFT => [
            <<~SPRITE,
              ╭──────╮
              │・◡・｡│
              ╰─ᜊ───ᜊ╯
            SPRITE
            <<~SPRITE,
              ╭──────╮
              │・◡・｡│
              ╰∪───∪─╯
            SPRITE
          ],
        },
        stunned: {
          RIGHT => [
            <<~SPRITE,
              ╭──────╮
              │ ´×⌓× │
              ╰─ᜊ───ᜊ╯
            SPRITE
            <<~SPRITE,
              ╭──────╮
              │ ´×⌓× │
              ╰─∪───∪╯
            SPRITE
          ],
          LEFT => [
            <<~SPRITE,
              ╭──────╮
              │ ×⌓×` │
              ╰─ᜊ───ᜊ╯
            SPRITE
            <<~SPRITE,
              ╭──────╮
              │ ×⌓×` │
              ╰─∪───∪╯
            SPRITE
          ],
        },
      }

      class << self
        def character(status, direction)
          CHARACTERS[status][direction].map do |lines|
            lines.split("\n").map do |line|
              line.chars.map do |character|
                fullwidth?(character) ? [character, ANSI::NULL] : character
              end.flatten
            end
          end
        end

        private

        def fullwidth?(character)
          %w[・].include? character
        end
      end
    end
  end
end
