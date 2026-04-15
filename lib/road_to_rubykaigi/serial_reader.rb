require 'singleton'
require 'uart'

module RoadToRubykaigi
  class SerialReader
    include Singleton

    BAUD = 115200

    class << self
      extend Forwardable
      def_delegators :instance, :start, :queue, :drain
    end

    attr_reader :queue

    def drain
      until @queue.empty?
        yield @queue.pop(true)
      end
    rescue ThreadError
      # pop(true) raises if the queue empties mid-drain
    end

    def start
      @queue.clear
      return if @thread

      @thread = Thread.new { read_loop }
      at_exit { @thread&.kill }
    end

    private

    def initialize
      @queue = Thread::Queue.new
      @port = Config.serial_port
    end

    def read_loop
      serial = UART.open(@port, BAUD)
      loop do
        line = serial.gets
        next unless line
        data = parse_line(line.strip)
        @queue.push(data) unless data.empty?
      end
    rescue => e
      $stderr.puts "[SerialReader] #{e.message}"
    ensure
      serial&.close
    end

    def parse_line(line)
      line.split(',').each_with_object({}) do |pair, hash|
        key, value = pair.split('=', 2)
        hash[key] = value if key && value
      end
    end
  end
end
