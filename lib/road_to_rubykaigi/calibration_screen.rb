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
      phase_header: [5, 6, "#{ANSI::BOLD}%-20s#{ANSI::RESET}  %.1fs"],
      phase_bar:    [5, 7, '[%s] %.4f'],
      done_static:  [5, 6, 'Static: %d samples'],
      done_walk:    [5, 7, 'Walk:   %d samples'],
      done_return:  [5, 10, '[Enter/ESC] return'],
    }.freeze

    CALIBRATION_LABELS = {
      static: 'Hold still 🧍',
      walk:   'Walk 🏃',
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
      @collect_label = CALIBRATION_LABELS[@current_key]
      @sampler = CalibrationSampler.new
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

    def draw_collect_bar
      filled = (@sampler.intensity / BAR_MAX * BAR_WIDTH).to_i.clamp(0, BAR_WIDTH)
      bar = '█' * filled + '░' * (BAR_WIDTH - filled)
      draw format_line(MESSAGES[:phase_header], "▶ #{label}", remaining),
           format_line(MESSAGES[:phase_bar], bar, intensity)
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
