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

      Variant = Data.define(:posture, :status, :direction, :default_frames, :attack_frames) do
        class << self
          def build(posture:, status:, direction:, parts:)
            new(
              posture: posture,
              status: status,
              direction: direction,
              default_frames: FRAMES.map { |frame| default_frame(posture, status, direction, frame, parts) },
              attack_frames:  FRAMES.map { |frame| attack_frame(posture, status, direction, frame, parts) },
            )
          end

          private

          def face_key(posture, status, direction) = :"face_#{posture}_#{status}_#{direction.name}"
          def foot_key(status, frame) = :"foot_#{status}_#{frame}"
          def crouching?(posture) = posture == :crouching

          def default_frame(posture, status, direction, frame, parts)
            [
              parts[:head],
              parts[face_key(posture, status, direction)],
              crouching?(posture) ? nil : parts[foot_key(status, frame)],
            ].compact
          end

          def attack_frame(posture, status, direction, frame, parts)
            head = parts[:head]
            face = parts[face_key(posture, status, direction)]
            foot = crouching?(posture) ? nil : parts[foot_key(status, frame)]

            if direction.right?
              [head + "   ".chars, face + "_◢◤".chars, foot && foot + "   ".chars].compact
            else
              ["   ".chars + head, "◥◣_".chars + face, foot && "   ".chars + foot].compact
            end
          end
        end
      end

      class << self
        def character(posture:, status:, direction:, attack_mode:)
          load_data unless @variants

          variant = @variants[[posture, status, direction]]
          attack_mode ? variant.attack_frames : variant.default_frames
        end

        private

        def load_data
          parts = load_parts
          @variants = POSTURES.product(STATUSES, DIRECTIONS).to_h do |posture, status, direction|
            [
              [posture, status, direction.value],
              Variant.build(posture:, status:, direction:, parts:),
            ]
          end
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
