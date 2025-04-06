module RoadToRubykaigi
  module Audio
    class SequencerBase
      BPM = 100
      NOTES = {
        REST: 0.0,
        C4: 261.63, C4s: 277.18, # ド
        D4: 293.66, D4s: 311.13,
        E4: 329.63,
        F4: 349.23, F4s: 369.99,
        G4: 392.00, G4s: 415.30, # ソ
        A4: 440.00, A4s: 466.16,
        B4: 493.88,
        C5: 523.25, C5s: 554.37,
        D5: 587.33, D5s: 622.25,
        E5: 659.25,
        F5: 698.46, F5s: 739.99,
        G5: 783.99, G5s: 830.61,
        A5: 880.00, A5s: 932.33,
        B5: 987.77,
        C6: 1046.50,
      }

      def generate
        process
        sample = if @current_note_sample_count < (@samples_per_note * self.class::STACCATO_RATIO)
          @generator.generate(frequencies: current_frequencies)
        else
          0.0
        end
        increment_current_note_sample_count
        sample
      end

      def sample_rate
        @generator.sample_rate
      end

      def gain
        @generator.gain
      end

      def rewind
        self
      end

      def finished?
        !loop? && @current_note_index >= @notes.size
      end

      private

      def initialize
        @bpm = BPM
        @notes = self.class::SCORE
        @current_note_index = 0
        @current_note_sample_count = 0
        @generator = self.class::GENERATOR.new
        change_note
      end

      def process
        if @current_note_sample_count >= @samples_per_note
          @current_note_index += 1
          @current_note_sample_count = 0
          if loop? && @current_note_index >= @notes.size
            @current_note_index -= @notes.size
          end
          change_note
        end
      end

      def current_note
        @notes[@current_note_index]
      end

      def current_frequencies
        current_note[:frequency].map { |frequency| NOTES[frequency] }
      end

      def change_note
        quarter_duration = 60.0 / @bpm
        @samples_per_note = (@generator.sample_rate * quarter_duration * current_note[:duration]).to_i
      end

      def increment_current_note_sample_count
        @current_note_sample_count += 1
      end
    end

    class BassSequencer < SequencerBase
      GENERATOR = SineOscillator
      STACCATO_RATIO = 0.3
      SCORE = ([
        { frequency: %i[F4 A4], duration: 1.0 },
        { frequency: %i[F4 A4], duration: 0.5 },
        { frequency: %i[C4 F4], duration: 1.0 },
        { frequency: %i[C4 F4], duration: 0.5 },
      ] * 5 + [
        { frequency: %i[F4], duration: 1.0 },
        { frequency: %i[C4], duration: 1.0 },
        { frequency: %i[E4], duration: 1.0 },
      ] +
      [
        { frequency: %i[F4 A4], duration: 1.0 },
        { frequency: %i[F4 A4], duration: 0.5 },
        { frequency: %i[C4 F4], duration: 1.0 },
        { frequency: %i[C4 F4], duration: 0.5 },
      ] * 4 + [
        { frequency: %i[F4 A4], duration: 1.0 },
        { frequency: %i[C4 F4], duration: 1.0 },
        { frequency: %i[F4], duration: 1.0 },

        { frequency: %i[E4], duration: 1.0 },
        { frequency: %i[D4], duration: 1.0 },
        { frequency: %i[C4], duration: 1.0 },
      ])

      private

      def loop?
        true
      end
    end

    class MelodySequencer < SequencerBase
      GENERATOR = SquareOscillator
      STACCATO_RATIO = 0.35
      SCORE = [ # 6 Measures
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },

        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[G5], duration: 0.5 },
        { frequency: %i[A5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[C5], duration: 0.5 },

        { frequency: %i[REST], duration: 0.5 },
        { frequency: %i[A5], duration: 0.5 },
        { frequency: %i[G5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[E5], duration: 1.0 },

        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[A4], duration: 0.5 },
        { frequency: %i[C5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[D5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[C5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },

        { frequency: %i[C5], duration: 1.0 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[A5], duration: 0.25 },
        { frequency: %i[C5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[C5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[C5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },

        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[A5], duration: 0.25 },
        { frequency: %i[G5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[E5], duration: 0.25 },
        { frequency: %i[F5], duration: 1.0 },
      ]

      def loop?
        true
      end
    end

    class FanfareSequencer < SequencerBase
      GENERATOR = SquareOscillator
      STACCATO_RATIO = 0.35
      SCORE = [ # 4.75 Measures
        { frequency: %i[REST], duration: 0.75 },

        { frequency: %i[F5], duration: 1.00 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },

        { frequency: %i[G5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[G5], duration: 0.5 },

        { frequency: %i[C5], duration: 0.25 },
        { frequency: %i[D5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[G5], duration: 0.25 },
        { frequency: %i[A5], duration: 0.25 },
        { frequency: %i[B5], duration: 0.25 },

        { frequency: %i[C6], duration: 1.5 },
      ]

      private

      def loop?
        false
      end
    end
  end
end
