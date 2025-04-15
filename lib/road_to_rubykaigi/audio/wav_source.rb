require 'wavefile'

module RoadToRubykaigi
  module Audio
    class WavSource
      include WaveFile

      def sample_rate
        44_100
      end

      def gain
        0.3
      end

      def generate
        if @position < @buffer.size
          sample = @buffer[@position]
          @position += 1
          sample
        else
          0.0
        end
      end

      def rewind
        @position = 0
        self
      end

      def finished?
        @position >= @buffer.size
      end

      private

      def initialize(path)
        @buffer = read_samples(path)
        @position = 0
      end

      def read_samples(path)
        samples = []
        pcm_rate = 2 ** (16 - 1)
        Reader.new(path).each_buffer(1024) do |buffer|
          buffer.samples.each do |sample|
            normalized = (sample.is_a?(Array) ? sample[0] : sample).to_f / pcm_rate
            samples << normalized
          end
        end
        samples
      end
    end
  end
end
