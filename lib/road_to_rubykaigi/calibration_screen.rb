module RoadToRubykaigi
  class CalibrationScreen
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
      print "\e[3;5H=== Sensor Calibration ==="
      print "\e[7;5H[Enter/Space] start  [ESC] return"
      $stdout.flush
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
      print "\e[3;5H=== Sensor Calibration ==="
      print "\e[10;5H[ESC] back"
      $stdout.flush
      latest = nil
      loop do
        case $stdin.read_nonblock(3, exception: false)
        when ANSI::ESC; return
        when ANSI::ETX; raise Interrupt
        end
        latest = drain_queue.last || latest
        render_sample(latest)
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

    def render_sample(latest)
      if latest
        x, y, z = latest
        print "\e[7;5Hx=#{format('%+.4f', x)}  y=#{format('%+.4f', y)}  z=#{format('%+.4f', z)}  "
      else
        print "\e[7;5H(waiting for data...)                   "
      end
      $stdout.flush
    end
  end
end
