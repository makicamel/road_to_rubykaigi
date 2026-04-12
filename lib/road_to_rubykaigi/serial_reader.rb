require 'singleton'

module RoadToRubykaigi
  class SerialReader
    include Singleton

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
      system('stty', '-f', @port, 'raw', '115200')
      File.open(@port, 'r') do |serial|
        serial.each_line do |line|
          data = parse_line(line.strip)
          @queue.push(data) unless data.empty?
        end
      end
    rescue => e
      $stderr.puts "[SerialReader] #{e.message}"
    end

    def parse_line(line)
      line.split(',').each_with_object({}) do |pair, hash|
        key, value = pair.split('=', 2)
        hash[key] = value if key && value
      end
    end
  end
end
