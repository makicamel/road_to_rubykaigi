require "logger"

module RoadToRubykaigi
  class GcLogger
    def self.start
      logger = Logger.new('log/gc_events.log')
      prev = { count: GC.stat[:count], time: GC.stat[:time] }

      Thread.new do
        loop do
          sleep 0.1
          stat = GC.stat
          delta_count = stat[:count] - prev[:count]
          delta_millisecond = stat[:time] - prev[:time]

          timestamp = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          logger.info format(
            "timestamp: %.3f, GC count: %2d, GC time: %.2f ms",
            timestamp,
            delta_count,
            delta_millisecond
          )

          prev = { count: stat[:count], time: stat[:time] }
        end
      end
    end
  end
end
