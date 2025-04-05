module RoadToRubykaigi
  module Audio
    module Phasor
      def sample_rate
        44_100
      end

      def gain
        0.4
      end

      private

      def initialize
        @phases = Hash.new { |h, k| h[k] = rand }
      end

      def tick(frequency:)
        phase = @phases[frequency]
        phase += frequency.to_f / sample_rate
        phase -= 1.0 if phase >= 1.0
        @phases[frequency] = phase
      end
    end

    class SineOscillator
      include Phasor

      def generate(frequencies:)
        samples = frequencies.map do |frequency|
          phase = tick(frequency: frequency)
          Math.sin(2 * Math::PI * phase)
        end
        samples.sum / samples.size
      end
    end

    class SquareOscillator
      include Phasor

      def generate(frequencies:)
        samples = frequencies.map do |frequency|
          phase = tick(frequency: frequency)
          phase < 0.5 ? 1.0 : -1.0
        end
        samples.sum / samples.size
      end
    end
  end
end
