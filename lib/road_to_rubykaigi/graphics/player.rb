module RoadToRubykaigi
  module Graphics
    module Player
      RIGHT = RoadToRubykaigi::Sprite::Player::RIGHT
      LEFT = RoadToRubykaigi::Sprite::Player::LEFT

      DEFAULT_CHARACTERS = {
        normal: {
          RIGHT => [
            <<~SPRITE.lines.map(&:chomp),
              ╭──────╮
              │｡・◡・│
              ╰ᜊ───ᜊ─╯
            SPRITE
            <<~SPRITE.lines.map(&:chomp),
              ╭──────╮
              │｡・◡・│
              ╰─∪───∪╯
            SPRITE
          ],
          LEFT => [
            <<~SPRITE.lines.map(&:chomp),
              ╭──────╮
              │・◡・｡│
              ╰─ᜊ───ᜊ╯
            SPRITE
            <<~SPRITE.lines.map(&:chomp),
              ╭──────╮
              │・◡・｡│
              ╰∪───∪─╯
            SPRITE
          ],
        },
        stunned: {
          RIGHT => [
            <<~SPRITE.lines.map(&:chomp),
              ╭──────╮
              │ ´×⌓× │
              ╰─ᜊ───ᜊ╯
            SPRITE
            <<~SPRITE.lines.map(&:chomp),
              ╭──────╮
              │ ´×⌓× │
              ╰─∪───∪╯
            SPRITE
          ],
          LEFT => [
            <<~SPRITE.lines.map(&:chomp),
              ╭──────╮
              │ ×⌓×` │
              ╰─ᜊ───ᜊ╯
            SPRITE
            <<~SPRITE.lines.map(&:chomp),
              ╭──────╮
              │ ×⌓×` │
              ╰─∪───∪╯
            SPRITE
          ],
        },
      }
      ATTACK_CHARACTERS = {
        normal: {
          RIGHT => DEFAULT_CHARACTERS[:normal][RIGHT].map do |character|
            character.map.with_index do |line, i|
              i == 1 ? line + "_◢◤" : line
            end
          end,
          LEFT => DEFAULT_CHARACTERS[:normal][LEFT].map.with_index do |character|
            character.map.with_index do |line, i|
              i == 1 ? "◥◣_" + line : "   " + line
            end
          end
        },
        stunned: {
          RIGHT => DEFAULT_CHARACTERS[:stunned][RIGHT].map do |character|
            character.map.with_index do |line, i|
              i == 1 ? line + "_◢◤" : line
            end
          end,
          LEFT => DEFAULT_CHARACTERS[:normal][LEFT].map.with_index do |character|
            character.map.with_index do |line, i|
              i == 1 ? "◥◣_" + line : "   " + line
            end
          end
        }
      }

      class << self
        def character(status, direction, attack_mode: false)
          characters = attack_mode ? ATTACK_CHARACTERS : DEFAULT_CHARACTERS
          characters[status][direction].map do |lines|
            lines.map do |line|
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
