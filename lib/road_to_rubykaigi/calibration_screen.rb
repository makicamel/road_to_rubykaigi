module RoadToRubykaigi
  class CalibrationScreen
    BAR_WIDTH = 100
    BAR_MAX = 1.0
    PHASE_DURATION = 3.0
    COUNTDOWN_FROM = 5

    def display
      GameServer.start
      $stdin.raw do
        loop do
          show_intro
          case wait_for_key
          when :back; return
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
      loop do
        case $stdin.read_nonblock(3, exception: false)
        when ANSI::ENTER, ANSI::LF, ANSI::SPACE
          return :proceed
        when ANSI::ESC
          return :back
        when ANSI::ETX
          raise Interrupt
        end
        sleep Manager::GameManager::FRAME_RATE
      end
    end

    def run_measure
      ANSI.clear
      draw [5, 3, '=== Sensor Calibration ==='],
           [5, 10, '[ESC] cancel'],
           [5, 12, 'Hold still for 3s'],
           [5, 13, 'Then walk for 3s']
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
      window = SignalWindow.new
      samples = []
      started_at = Time.now
      metric = 0.0
      loop do
        return nil if cancelled?
        elapsed = Time.now - started_at
        break if elapsed >= PHASE_DURATION
        drain_queue.each { |sample| window.buffer_sample(sample) }
        if window.full?
          metric = window.motion_intensity
          samples << metric
        end
        render_phase(label, metric, PHASE_DURATION - elapsed)
        sleep Manager::GameManager::FRAME_RATE
      end
      samples
    end

    def render_phase(label, metric, remaining)
      filled = (metric / BAR_MAX * BAR_WIDTH).to_i.clamp(0, BAR_WIDTH)
      bar = '█' * filled + '░' * (BAR_WIDTH - filled)
      header = "▶ #{label}".ljust(20)
      draw [5, 6, "\e[1m#{header}\e[0m  #{format('%.1fs', remaining)}"],
           [5, 7, "[#{bar}] #{format('%.4f', metric)}"]
    end

    def show_done(static_count, walk_count)
      ANSI.clear
      draw [5, 3, '=== Sensor Calibration ==='],
           [5, 6, "Static: #{static_count} samples"],
           [5, 7, "Walk:   #{walk_count} samples"],
           [5, 10, '[Enter/ESC] return']
      wait_for_key
    end

    def cancelled?
      case $stdin.read_nonblock(3, exception: false)
      when ANSI::ESC then true
      when ANSI::ETX then raise Interrupt
      else false
      end
    end

    def drain_queue
      samples = []
      until GameServer.queue.empty?
        data = GameServer.queue.pop(true)
        next unless %w[x y z].all? { |key| data.key?(key) }
        samples << [data['x'].to_f, data['y'].to_f, data['z'].to_f]
      end
      samples
    rescue ThreadError
      samples
    end

    def draw(*lines)
      lines.each { |x, y, text| print "\e[#{y};#{x}H#{text}" }
      $stdout.flush
    end
  end
end
