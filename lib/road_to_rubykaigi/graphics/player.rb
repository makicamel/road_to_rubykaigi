module RoadToRubykaigi
  module Graphics
    module Player
      RIGHT = RoadToRubykaigi::Sprite::Player::RIGHT
      LEFT = RoadToRubykaigi::Sprite::Player::LEFT
      FILE_PATH = "player.txt"

      POSTURES = %i[standup crouching].freeze
      STATUSES = %i[normal stunned].freeze
      FRAMES = [1, 2].freeze

      Direction = Data.define(:value) do
        def right? = value == RIGHT
        def name = right? ? 'RIGHT' : 'LEFT'
      end
      DIRECTIONS = [Direction.new(RIGHT), Direction.new(LEFT)].freeze

      Variant = Data.define(:posture, :status, :direction, :frame) do
        def face_key = :"face_#{posture}_#{status}_#{direction.name}"
        def foot_key = :"foot_#{status}_#{frame}"
        def crouching? = posture == :crouching

        def default_frame(parts)
          [
            parts[:head],
            parts[face_key],
            crouching? ? nil : parts[foot_key],
          ].compact
        end

        def attack_frame(parts)
          head = parts[:head]
          face = parts[face_key]
          foot = crouching? ? nil : parts[foot_key]

          if direction.right?
            [head + "   ".chars, face + "_◢◤".chars, foot && foot + "   ".chars].compact
          else
            ["   ".chars + head, "◥◣_".chars + face, foot && "   ".chars + foot].compact
          end
        end
      end

      class << self
        def character(posture:, status:, direction:, attack_mode:)
          load_data unless @default_characters

          characters = attack_mode ? @attack_characters : @default_characters
          characters[posture][status][direction]
        end

        private

        def load_data
          @default_characters = empty_store
          @attack_characters = empty_store
          parts = load_parts

          POSTURES.product(STATUSES, DIRECTIONS, FRAMES).each do |posture, status, direction, frame|
            variant = Variant.new(posture:, status:, direction:, frame:)
            @default_characters[posture][status][direction.value] << variant.default_frame(parts)
            @attack_characters[posture][status][direction.value] << variant.attack_frame(parts)
          end
        end

        # @return [Hash] {standup: {normal: {}, stunned: {}}, crouching: {normal: {}, stunned: {}}}
        def empty_store
          store_template = Hash.new { |h, k| h[k] = [] }
          POSTURES.to_h { |posture| [posture, STATUSES.to_h { |status| [status, store_template.dup] }] }
        end

        # @return [Hash{Symbol => Array<String>}]
        #   {head: ["╭", "─", "─", "─", "─", "─", "─", "╮"],
        #    foot_normal_1: ["╰", "─", "∪", "─", "─", "─", "∪", "╯"],
        #    face_standup_normal_RIGHT: ["│", "｡", "・", "\u0000", "◡", "・", "\u0000", "│"], ...
        def load_parts
          File.read("#{__dir__}/#{FILE_PATH}")
              .scan(/^# (\w+)\n(.*)$/)
              .to_h { |name, line| [name.to_sym, expand_cells(line)] }
        end

        def expand_cells(line)
          line.chars.flat_map { |char| fullwidth?(char) ? [char, ANSI::NULL] : [char] }
        end

        def fullwidth?(char)
          %w[・].include? char
        end
      end
    end
  end
end
