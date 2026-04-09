module RoadToRubykaigi
  class CalibrationScreen
    BAR_WIDTH = 100
    BAR_MAX = 1.0
    COUNTDOWN_FROM = 5

    def display
      GameServer.start
      $stdin.raw do
        loop do
          show_intro
          case wait_for_key
          when :cancel; return
          when :proceed; run_measure
          end
        end
      end
    end

    private

    def show_intro
      ANSI.clear
      draw [5, 3, '=== Sensor Calibration ==='],
           [5, 7, '[Enter/Space] start'],
           [5, 8, '[ESC]         return']
    end

    def wait_for_key
      until (action = read_action)
        sleep Manager::GameManager::FRAME_RATE
      end
      action
    end

    def run_measure
      ANSI.clear
      draw [5, 3, '=== Sensor Calibration ==='],
           [5, 10, '[ESC] cancel'],
           [5, 12, "Hold still for #{phase_seconds}s"],
           [5, 13, "Then walk for #{phase_seconds}s"]
      return unless run_countdown
      clear_instructions
      static = collect_phase('Hold still 🧍')
      return unless static
      walk = collect_phase('Walk 🏃')
      return unless walk
      show_done(static.size, walk.size)
    end

    def run_countdown
      COUNTDOWN_FROM.downto(1) do |n|
        return false if cancelled?
        draw [5, 8, "Starting in #{n}..."]
        sleep 1.0
      end
      draw [5, 8, ' ' * 20]
      true
    end

    def clear_instructions
      draw [5, 12, ' ' * 30],
           [5, 13, ' ' * 30]
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
      header = "▶ #{label}".ljust(20)
      draw [5, 6, "\e[1m#{header}\e[0m  #{format('%.1fs', remaining)}"],
           [5, 7, "[#{bar}] #{format('%.4f', intensity)}"]
    end

    def show_done(static_count, walk_count)
      ANSI.clear
      draw [5, 3, '=== Sensor Calibration ==='],
           [5, 6, "Static: #{static_count} samples"],
           [5, 7, "Walk:   #{walk_count} samples"],
           [5, 10, '[Enter/ESC] return']
      wait_for_key
    end

    def phase_seconds = CalibrationSampler::PHASE_SECONDS

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
