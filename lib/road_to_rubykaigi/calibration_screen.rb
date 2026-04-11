module RoadToRubykaigi
  class CalibrationScreen
    BAR_WIDTH = 100
    BAR_MAX = 1.0
    COUNTDOWN_FROM = 5

    MESSAGES = {
      title: [5, 3, '=== Sensor Calibration ==='],
      intro: [
        [5, 7, '[Enter/Space] start'],
        [5, 8, '[ESC]         return'],
      ],
      measure: [
        [5, 10, '[ESC] cancel'],
        [5, 12, "Hold still for #{CalibrationSampler::PHASE_SECONDS}s"],
        [5, 13, "Then walk for #{CalibrationSampler::PHASE_SECONDS}s"],
      ],
      clear_instructions: [
        [5, 12, ' ' * 30],
        [5, 13, ' ' * 30],
      ],
      countdown:    [5, 8, 'Starting in %d...'],
      countdown_clear: [5, 8, ' ' * 20],
      remaining: [5, 5, "#{ANSI::BOLD}%-20s#{ANSI::RESET}  %5.1fs"],
      intensity: [5, 8, '[%s] %.4f'],
      done_static:  [5, 6, 'Static: %d samples'],
      done_walk:    [5, 7, 'Walk:   %d samples'],
      done_return:  [5, 10, '[Enter/ESC] return'],
    }.freeze

    CALIBRATION_LABELS = {
      static: { text: 'Hold still', emoji: '🧍' },
      walk:   { text: 'Walk',       emoji: '🏃‍➡️', emoji_ground: '🚶‍➡️' },
    }.freeze

    def display
      GameServer.start
      @state = :intro
      @results = {}
      @remaining_keys = CALIBRATION_LABELS.keys.dup
      $stdin.raw do
        loop do
          case tick
          when :done then return
          end
          sleep Manager::GameManager::FRAME_RATE
        end
      end
    end

    private

    def tick
      action = read_action
      if action == :cancel
        if @state == :intro || @state == :done
          return :done 
        else
          enter_intro && return
        end
      end

      case @state
      when :intro     then action == :proceed && enter_countdown
      when :countdown then tick_countdown
      when :collect   then tick_collect
      when :done      then action == :proceed && enter_intro
      end
    end

    def enter_intro
      @state = :intro
      @results = {}
      @remaining_keys = CALIBRATION_LABELS.keys.dup
      ANSI.clear
      draw MESSAGES[:title], *MESSAGES[:intro]
    end

    def enter_countdown
      @state = :countdown
      @countdown_remaining = COUNTDOWN_FROM
      @countdown_last_tick = nil
      ANSI.clear
      draw MESSAGES[:title], *MESSAGES[:measure]
    end

    def tick_countdown
      now = Time.now
      @countdown_last_tick ||= now

      if now - @countdown_last_tick >= 1.0
        @countdown_remaining -= 1
        @countdown_last_tick = now
      end

      if @countdown_remaining <= 0
        draw MESSAGES[:countdown_clear]
        enter_collect
      else
        draw format_line(MESSAGES[:countdown], @countdown_remaining)
      end
    end

    def enter_collect
      @state = :collect
      @current_key = @remaining_keys.first
      @sampler = CalibrationSampler.new
      @prev_emoji_x = COLLECT_BAR_BASE_X + 1
      draw *MESSAGES[:clear_instructions]
    end

    def tick_collect
      @sampler.tick
      draw_collect_bar

      return unless @sampler.finished?

      @results[@current_key] = @sampler.samples
      @remaining_keys.shift

      if @remaining_keys.empty?
        enter_done
      else
        enter_collect
      end
    end

    EMOJI_WIDTH = 2
    BOUNCE_HZ = 4

    COLLECT_BAR_BASE_X = 5
    EMOJI_BOUNCE_ROW = 6
    EMOJI_BASE_ROW = EMOJI_BOUNCE_ROW + 1

    def draw_collect_bar
      filled = (@sampler.intensity / BAR_MAX * BAR_WIDTH).to_i.clamp(0, BAR_WIDTH)
      bar = '█' * filled + '░' * (BAR_WIDTH - filled)
      current_label = CALIBRATION_LABELS[@current_key]
      lines = [
        format_line(MESSAGES[:remaining], "▶ #{current_label[:text]}", @sampler.remaining),
        format_line(MESSAGES[:intensity], bar, @sampler.intensity),
      ]

      if @current_key == :walk
        emoji_x = COLLECT_BAR_BASE_X + 1 + (@sampler.progress * BAR_WIDTH).to_i.clamp(0, BAR_WIDTH)
        bouncing = (Time.now.to_f * BOUNCE_HZ).to_i.odd?
        unless @prev_emoji_x == emoji_x
          lines << [@prev_emoji_x, EMOJI_BASE_ROW, ' ' * EMOJI_WIDTH]
          lines << [@prev_emoji_x, EMOJI_BOUNCE_ROW, ' ' * EMOJI_WIDTH]
          @prev_emoji_x = emoji_x
        end
        if bouncing
          lines << [emoji_x, EMOJI_BOUNCE_ROW, current_label[:emoji]]
          lines << [emoji_x, EMOJI_BASE_ROW, ' ' * EMOJI_WIDTH]
        else
          lines << [emoji_x, EMOJI_BASE_ROW, current_label[:emoji_ground]]
          lines << [emoji_x, EMOJI_BOUNCE_ROW, ' ' * EMOJI_WIDTH]
        end
      else
        emoji_x = COLLECT_BAR_BASE_X + 1
        lines << [emoji_x, EMOJI_BASE_ROW, current_label[:emoji]]
      end

      draw *lines
    end

    def enter_done
      @state = :done
      ANSI.clear
      draw MESSAGES[:title],
           format_line(MESSAGES[:done_static], @results[:static].size),
           format_line(MESSAGES[:done_walk], @results[:walk].size),
           MESSAGES[:done_return]
    end

    def format_line(line, *args)
      x, y, template = line
      [x, y, format(template, *args)]
    end

    def read_action
      case $stdin.read_nonblock(3, exception: false)
      when ANSI::ETX then raise Interrupt
      when ANSI::ENTER, ANSI::LF, ANSI::SPACE then :proceed
      when ANSI::ESC then :cancel
      end
    end

    def draw(*lines)
      lines.each { |x, y, text| print "\e[#{y};#{x}H#{text}" }
      $stdout.flush
    end
  end
end
