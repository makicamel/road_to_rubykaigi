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

    def display
      GameServer.start
      $stdin.raw do
        loop do
          ANSI.clear
          draw MESSAGES[:title], *MESSAGES[:intro]

          case wait_for_key
          when :cancel; return
          when :proceed; run_measure
          end
        end
      end
    end

    private

    def wait_for_key
      until (action = read_action)
        sleep Manager::GameManager::FRAME_RATE
      end
      action
    end

    def run_measure
      ANSI.clear
      draw MESSAGES[:title], *MESSAGES[:measure]
      return unless run_countdown
      draw *MESSAGES[:clear_instructions]
      static = collect_phase('Hold still 🧍')
      return unless static
      walk = collect_phase('Walk 🏃')
      return unless walk
      show_done(static.size, walk.size)
    end

    def run_countdown
      COUNTDOWN_FROM.downto(1) do |n|
        return false if cancelled?
        draw format_line(MESSAGES[:countdown], n)
        sleep 1.0
      end
      draw MESSAGES[:countdown_clear]
      true
    end

    def collect_phase(label)
      sampler = CalibrationSampler.new
      until sampler.finished?
        return nil if cancelled?
        sampler.tick
        render_phase(label, sampler.intensity, sampler.remaining)
        sleep Manager::GameManager::FRAME_RATE
      end
      sampler.samples
    end

    def render_phase(label, intensity, remaining)
      filled = (intensity / BAR_MAX * BAR_WIDTH).to_i.clamp(0, BAR_WIDTH)
      bar = '█' * filled + '░' * (BAR_WIDTH - filled)
      draw format_line(MESSAGES[:phase_header], "▶ #{label}", remaining),
           format_line(MESSAGES[:phase_bar], bar, intensity)
    end

    def show_done(static_count, walk_count)
      ANSI.clear
      draw MESSAGES[:title],
           format_line(MESSAGES[:done_static], static_count),
           format_line(MESSAGES[:done_walk], walk_count),
           MESSAGES[:done_return]
      wait_for_key
    end

    def format_line(line, *args)
      x, y, template = line
      [x, y, format(template, *args)]
    end

    def cancelled? = read_action == :cancel

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
