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

    class RoundedSquareOscillator
      include Phasor
      DUTY_CYCLE = {
        d0: 0.125,
        d1: 0.25,
        d2: 0.5,
      }
      SMOOTH_WIDTH = 0.05

      def generate(frequencies:)
        samples = frequencies.map do |frequency|
          phase = tick(frequency: frequency)
          off_to_on_end = SMOOTH_WIDTH / 2.0
          on_to_off_start = duty_cycle - SMOOTH_WIDTH / 2.0
          on_to_off_end = duty_cycle + SMOOTH_WIDTH / 2.0

          case phase
          when 0..off_to_on_end
            t = phase / off_to_on_end
            smoothstep_weight = t ** 2 * (3 - 2 * t)
            -1.0 + smoothstep_weight * 2
          when off_to_on_end..on_to_off_start
            1.0
          when on_to_off_start..on_to_off_end
            t = (phase - on_to_off_start) / SMOOTH_WIDTH
            cos_weight = 1 - Math.cos(Math::PI * t)
            1.0 - cos_weight
          else
            # We don't need interpolate off_to_on_start..1
            # because 1 is essentially contiguous with 0.
            -1.0
          end
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
