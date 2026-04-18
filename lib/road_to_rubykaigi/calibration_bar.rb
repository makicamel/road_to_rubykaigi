module RoadToRubykaigi
  class CalibrationBar
    BAR_WIDTH = 100
    BAR_MAX = 1.0
    EMOJI_WIDTH = 2
    BOUNCE_HZ = 4

    BASE_X = 5
    EMOJI_BOUNCE_Y = 6
    EMOJI_BASE_Y = EMOJI_BOUNCE_Y + 1

    MESSAGES = {
      remaining: [5, 5, "#{ANSI::BOLD}%-20s#{ANSI::RESET}  %5.1fs"],
      intensity: [5, 8, '[%s] %.4f'],
    }.freeze

    LABELS = {
      static: { text: 'Hold still', emoji: '🧍' },
      walk:   { text: 'Walk',       emoji: '🚶‍➡️', emoji_bounce: '🏃‍➡️' },
      jump:   { text: 'Jump',       emoji: '🧍',    emoji_bounce: '🤸' },
    }.freeze

    def self.states = LABELS.keys.dup

    def render
      result = [
        format_line(MESSAGES[:remaining], "▶ #{@label[:text]}", @sampler.remaining),
        format_line(MESSAGES[:intensity], bar, @sampler.intensity),
      ]

      if bouncing_state?
        emoji_x = BASE_X + 1 + (@sampler.progress * BAR_WIDTH).to_i.clamp(0, BAR_WIDTH)
        # Clear previous emoji
        unless @prev_emoji_x == emoji_x
          result << [@prev_emoji_x, EMOJI_BOUNCE_Y, ' ' * EMOJI_WIDTH]
          result << [@prev_emoji_x, EMOJI_BASE_Y, ' ' * EMOJI_WIDTH]
          @prev_emoji_x = emoji_x
        end

        if bouncing?
          result << [emoji_x, EMOJI_BOUNCE_Y, @label[:emoji_bounce]]
          result << [emoji_x, EMOJI_BASE_Y, ' ' * EMOJI_WIDTH]
        else
          result << [emoji_x, EMOJI_BOUNCE_Y, ' ' * EMOJI_WIDTH]
          result << [emoji_x, EMOJI_BASE_Y, @label[:emoji]]
        end
      else
        result << [BASE_X + 1, EMOJI_BASE_Y, @label[:emoji]]
      end

      result
    end

    private

    def initialize(sampler, state:)
      @sampler = sampler
      @state = state
      @label = LABELS.fetch(state)
      @prev_emoji_x = BASE_X + 1
    end

    def bar
      filled = (@sampler.intensity / BAR_MAX * BAR_WIDTH).to_i.clamp(0, BAR_WIDTH)
      '█' * filled + '░' * (BAR_WIDTH - filled)
    end

    def bouncing_state? = @label.key?(:emoji_bounce)
    def bouncing? = (Time.now.to_f * BOUNCE_HZ).to_i.odd?

    def format_line(line, *args)
      x, y, template = line
      [x, y, format(template, *args)]
    end
  end
end
