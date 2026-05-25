require 'logger'

module RoadToRubykaigi
  # Resolves a signal-source sample into an event.
  # - Pico-encoded (`e=` present)
  #  The Pico already ran SignalInterpreter; decode it from the encoded line.
  # - Raw x/y/z (no `e=`)
  #  The sample is the plain accelerometer reading; fall back to
  #  running SignalInterpreter on the host.
  #
  # Encoded form inside a `key=value,...` line:
  #   e=j             -> :jump
  #   e=s             -> :stop
  #   e=w,d=R,s=1.23  -> Walk.new(direction: :right, speed_ratio: 1.23)
  #   e=h             -> nil (heartbeat — no event this tick)
  #
  # `e=h` and any unknown encoded value fall through to nil (no event),
  # which the caller treats as a no-op tick.
  module EventDecoder
    class << self
      def decode(data)
        event =
          case data['e']
          when 'j' then :jump
          when 's' then :stop
          when 'w'
            Walk.new(
              direction: data['d'] == 'R' ? :right : :left,
              speed_ratio: data['s'].to_f,
            )
          when nil
            SignalInterpreter.process(data) # raw stream
          end
        logger.info(event.inspect) if event
        event
      end

      private

      def logger
        @logger ||= Logger.new(
          Config.debug? ? File.join(Config.project_root, 'tmp/event_decoder.log') : File::NULL
        )
      end
    end
  end
end
