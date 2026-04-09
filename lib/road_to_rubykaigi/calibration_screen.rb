module RoadToRubykaigi
  class CalibrationScreen
    def display
      ANSI.clear
      render
      $stdin.raw do
        loop do
          case $stdin.read_nonblock(3, exception: false)
          when ANSI::ESC; return
          when ANSI::ETX; raise Interrupt
          end
          sleep Manager::GameManager::FRAME_RATE
        end
      end
    end

    private

    def render
      print "\e[3;5H=== Sensor Calibration ==="
      print "\e[7;5H[ESC] to return"
      $stdout.flush
    end
  end
end
