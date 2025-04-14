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
      ENVELOPE = {
        bass:        { a: 0.2, d: 0.2, s: 0.6, sl: 0.6, rl: 0.9 },
        bass_short:  { a: 0.2, d: 0.2, s: 0.05, sl: 0.6, rl: 0.9 },
        melody:      { a: 0.05, d: 0.1, s: 0.1, sl: 0.75, rl: 1.35 },
        melody_long: { a: 0.5, d: 0.2, s: 0.7, sl: 0.6, rl: 1.0 },
        fanfare:     { a: 0.2, d: 0.1, s: 0.35, sl: 0.6, rl: 1.5 },
      }

      def generate
        process
        env = envelope
        sample = if @current_note_sample_count < (@samples_per_note * staccato_ratio)
          @generator.generate(frequencies: current_frequencies)
        else
          0.0
        end
        increment_current_note_sample_count
        sample * env
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

      def envelope
        note_progress = @current_note_sample_count.to_f / (@samples_per_note * staccato_ratio)
        current_envelop = Hash === current_note[:envelope] ? current_note[:envelope] : ENVELOPE[current_note[:envelope] || default_envelop_key]
        attack = current_envelop[:a]
        decay = current_envelop[:d]
        sustain_level = current_envelop[:sl]
        release_level = current_envelop[:rl]
        sustain = current_envelop[:s]

        if note_progress < attack
          note_progress / attack
        elsif note_progress < (attack + decay)
          1 - ((note_progress - attack) / decay) * (1 - sustain_level)
        elsif note_progress < sustain
          sustain_level
        else
          (1 - note_progress) / release_level
        end
      end

      def current_note
        @notes[@current_note_index]
      end

      def current_frequencies
        current_note[:frequency].map { |frequency| NOTES[frequency] }
      end

      def staccato_ratio
        current_note[:staccato] || self.class::STACCATO_RATIO
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
      GENERATOR = RoughTriangleOscillator
      STACCATO_RATIO = 0.85
      SCORE = ([
        { frequency: %i[F4 A4], duration: 1.0 },
        { frequency: %i[F4 A4], duration: 0.5, envelope: :bass_short, staccato: 0.7 },
        { frequency: %i[C4 F4], duration: 1.0 },
        { frequency: %i[C4 F4], duration: 0.5, envelope: :bass_short, staccato: 0.7 },
      ] * 5 + [
        { frequency: %i[F4], duration: 1.0 },
        { frequency: %i[C4], duration: 1.0 },
        { frequency: %i[E4], duration: 1.0, staccato: 1.0 },
      ] +
      [
        { frequency: %i[F4 A4], duration: 1.0 },
        { frequency: %i[F4 A4], duration: 0.5, envelope: :bass_short, staccato: 0.7 },
        { frequency: %i[C4 F4], duration: 1.0 },
        { frequency: %i[C4 F4], duration: 0.5, envelope: :bass_short, staccato: 0.7 },
      ] * 4 + [
        { frequency: %i[F4 A4], duration: 1.0 },
        { frequency: %i[C4 F4], duration: 1.0 },
        { frequency: %i[F4], duration: 1.0 },

        { frequency: %i[E4], duration: 1.0 },
        { frequency: %i[D4], duration: 1.0 },
        { frequency: %i[C4], duration: 1.0, staccato: 1.0 },
      ])

      private

      def default_envelop_key
        :bass
      end

      def loop?
        true
      end
    end

    class MelodySequencer < SequencerBase
      GENERATOR = RoundedSquareOscillator
      STACCATO_RATIO = 0.35
      SCORE = [ # 6 Measures
        { frequency: %i[F5], duration: 0.5, envelope: { a: 0.05, d: 0.0, s: 0.5, sl: 0.4, rl: 1.0 } },
        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },

        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[G5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },

        { frequency: %i[REST], duration: 0.5 },
        { frequency: %i[A5], duration: 0.5 },
        { frequency: %i[G5], duration: 0.5 },
        { frequency: %i[F5], duration: 0.5 },
        { frequency: %i[E5], duration: 1.0, envelope: :melody_long, staccato: 0.95 },

        { frequency: %i[F5], duration: 0.5, envelope: { a: 0.15, d: 0.15, s: 0.5, sl: 0.4, rl: 0.9 } },
        { frequency: %i[C5], duration: 0.5 },
        { frequency: %i[A4], duration: 0.5 },
        { frequency: %i[C5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[D5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },
        { frequency: %i[C5], duration: 0.25 },
        { frequency: %i[F5], duration: 0.25 },

        { frequency: %i[C5], duration: 1.0, envelope: { a: 0.5, d: 0.15, s: 0.7, sl: 0.5, rl: 0.5 }, staccato: 0.95 },
        { frequency: %i[F5], duration: 0.25, envelope: { a: 0.05, d: 0.0, s: 0.5, sl: 0.4, rl: 1.0 } },
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
        { frequency: %i[F5], duration: 1.0, envelope: :melody_long, staccato: 0.95 },
      ]

      def loop?
        true
      end

      private

      def default_envelop_key
        :melody
      end
    end

    class FanfareSequencer < SequencerBase
      GENERATOR = RoundedSquareOscillator
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

        { frequency: %i[C6], duration: 1.8, envelope: { a: 0.2, d: 0.2, s: 0.6, sl: 0.6, rl: 0.9 } },
      ]

      private

      def default_envelop_key
        :fanfare
      end

      def loop?
        false
      end
    end
  end
end
