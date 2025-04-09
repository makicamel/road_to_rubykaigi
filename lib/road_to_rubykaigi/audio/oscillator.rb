module RoadToRubykaigi
  module Audio
    module Phasor
      def sample_rate
        44_100
      end

      def gain
        0.2
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

    class TriangleOscillator
      include Phasor

      def generate(frequencies:)
        samples = frequencies.map do |frequency|
          phase = tick(frequency: frequency)
          if phase < 0.5
            4 * phase - 1
          else
            -4 * phase + 3
          end
        end
        samples.sum / samples.size
      end
    end

    class RoughTriangleOscillator
      include Phasor

      TABLE_SIZE = 32

      def generate(frequencies:)
        samples = frequencies.map do |frequency|
          phase = tick(frequency: frequency)
          index = (TABLE_SIZE * phase).floor % TABLE_SIZE
          @table[index]
        end
        samples.sum / samples.size
      end

      private

      def initialize
        super
        @table = generate_table
      end

      def generate_table
        half = TABLE_SIZE / 2
        # up：-1 -> +1
        #   i = 0: -1.0, i = half-1: +1.0
        up = (0...half).map { |i| -1.0 + (2.0 * i) / (half - 1) }
        # down：+1 -> -1
        #   i = 0: +1.0, i = half-1: -1.0
        down = (0...half).map { |i| 1.0 - (2.0 * i) / (half - 1) }
        up + down
      end
    end

    class SquareOscillator
      include Phasor
      DUTY_CYCLE = {
        d0: 0.125,
        d1: 0.25,
        d2: 0.5,
      }

      def generate(frequencies:)
        samples = frequencies.map do |frequency|
          phase = tick(frequency: frequency)
          phase < duty_cycle ? 1.0 : -1.0
        end
        samples.sum / samples.size
      end

      def duty_cycle=(duty_cycle)
        @duty_cycle = (DUTY_CYCLE.key?(duty_cycle) ? duty_cycle : :d0)
      end

      private

      def initialize
        @duty_cycle = :d1
        super
      end

      def duty_cycle
        DUTY_CYCLE[@duty_cycle]
      end
    end
  end
end
