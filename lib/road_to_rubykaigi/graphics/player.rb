module RoadToRubykaigi
  module Graphics
    module Player
      RIGHT = RoadToRubykaigi::Sprite::Player::RIGHT
      LEFT = RoadToRubykaigi::Sprite::Player::LEFT
      FILE_PATH = "player.txt"

      class << self
        def character(posture:, status:, direction:, attack_mode:)
          load_data
          characters = attack_mode ? @attack_characters : @default_characters
          characters[posture][status][direction]
        end

        private

        def load_data
          return if @default_characters
          index = { "RIGHT" => Sprite::Player::RIGHT, "LEFT" => Sprite::Player::LEFT }
          hash = Hash.new { |h, k| h[k] = [] }
          @default_characters = {
            standup: { normal: hash.dup, stunned: hash.dup },
            crouching: { normal: hash.dup, stunned: hash.dup },
          }
          @attack_characters = {
            standup: { normal: hash.dup, stunned: hash.dup },
            crouching: { normal: hash.dup, stunned: hash.dup },
          }
          set = {}
          data = File.read("#{__dir__}/#{FILE_PATH}").scan(/# (\w+)\n(.*)\n/) do |type, line|
            set[type.to_sym] = line.chars.map do |char|
              fullwidth?(char) ? [char, ANSI::NULL] : char
            end.flatten
          end

          %i[standup crouching].each do |posture|
            %i[normal stunned].each do |status|
              index.each do |(direction, direction_value)|
                (1..2).each do |i|
                  @default_characters[posture][status][direction_value] << (
                    [
                      set[:head],
                      set["face_#{posture}_#{status}_#{direction}".to_sym],
                      set["foot_#{status}_#{i}".to_sym],
                    ]
                  )
                  @attack_characters[posture][status][direction_value] << (
                    direction == "RIGHT" ?
                      [
                        set[:head] + "   ".chars,
                        set["face_#{posture}_#{status}_#{direction}".to_sym] + "_◢◤".chars,
                        set["foot_#{status}_#{i}".to_sym] + "   ".chars,
                      ] :
                      [
                        "   ".chars + set[:head],
                        "◥◣_".chars + set["face_#{posture}_#{status}_#{direction}".to_sym],
                        "   ".chars + set["foot_#{status}_#{i}".to_sym],
                      ]
                  )
                end
              end
            end
          end
        end

        def fullwidth?(char)
          %w[・].include? char
        end
      end
    end
  end
end
