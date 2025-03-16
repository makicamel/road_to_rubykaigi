module RoadToRubykaigi
  module Graphics
    module Player
      RIGHT = RoadToRubykaigi::Sprite::Player::RIGHT
      LEFT = RoadToRubykaigi::Sprite::Player::LEFT
      FILE_PATH = "player.txt"

      class << self
        def character(status, direction, attack_mode:)
          load_data
          characters = attack_mode ? @attack_characters : @normal_characters
          characters[status][direction]
        end

        private

        def load_data
          return if @normal_characters
          index = { "RIGHT" => Sprite::Player::RIGHT, "LEFT" => Sprite::Player::LEFT }
          @normal_characters = {
            normal: { index["RIGHT"] => [], index["LEFT"] => [] },
            stunned: { index["RIGHT"] => [], index["LEFT"] => [] },
            crouching: { index["RIGHT"] => [], index["LEFT"] => [] },
          }
          @attack_characters = {
            normal: { index["RIGHT"] => [], index["LEFT"] => [] },
            stunned: { index["RIGHT"] => [], index["LEFT"] => [] },
            crouching: { index["RIGHT"] => [], index["LEFT"] => [] },
          }
          data = File.read("#{__dir__}/#{FILE_PATH}").scan(/# (normal|stunned|crouching)_(RIGHT|LEFT)_(\d)\n((?:[^#]+\n){4,6})/) do |raw_status, direction, height, raw_frames|
            status = raw_status.to_sym
            normal_frames = raw_frames.lines.map do |line|
              line.chomp.chars.map do |char|
                fullwidth?(char) ? [char, ANSI::NULL] : char
              end.flatten
            end.each_slice(height.to_i).to_a
            @normal_characters[status][index[direction]] = normal_frames
            attack_frames = normal_frames.map do |character|
              character.map.with_index do |line, i|
                if i == 1
                  direction == "RIGHT" ? line + "_◢◤".chars : "◥◣_".chars + line
                else
                  direction == "RIGHT" ? line + "   ".chars : "   ".chars + line
                end
              end
            end
            @attack_characters[status][index[direction]] = attack_frames
          end
        end

        def fullwidth?(char)
          %w[・].include? char
        end
      end
    end
  end
end
