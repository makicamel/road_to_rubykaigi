module RoadToRubykaigi
  class CalibrationScreen
    BAR_WIDTH = 100
    BAR_MAX = 1.0

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
           [5, 10, '[ESC] back']
      window = SignalWindow.new
      metric = 0.0
      loop do
        case $stdin.read_nonblock(3, exception: false)
        when ANSI::ESC; return
        when ANSI::ETX; raise Interrupt
        end
        drain_queue.each { |sample| window.buffer_sample(sample) }
        metric = window.motion_intensity if window.full?
        render_metric(metric)
        sleep Manager::GameManager::FRAME_RATE
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

    def render_metric(metric)
      filled = (metric / BAR_MAX * BAR_WIDTH).to_i.clamp(0, BAR_WIDTH)
      bar = '█' * filled + '░' * (BAR_WIDTH - filled)
      draw [5, 7, "[#{bar}] #{format('%.4f', metric)}"]
    end

    def draw(*lines)
      lines.each { |x, y, text| print "\e[#{y};#{x}H#{text}" }
      $stdout.flush
    end
  end
end
