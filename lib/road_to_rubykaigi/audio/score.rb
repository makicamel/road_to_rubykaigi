module RoadToRubykaigi
  module Audio
    class NoteSequencer
      BPM = 120
      STACCATO_RATIO = 0.3
      NOTES = {
        C4: 261.63, # ド
        C4s: 277.18,
        D4: 293.66,
        D4s: 311.13,
        E4: 329.63,
        F4: 349.23,
        F4s: 369.99,
        G4: 392.00, # ソ
        G4s: 415.30,
        A4: 440.00,
        A4s: 466.16,
        B4: 493.88,
        C5: 523.25,
        C5s: 554.37,
        D5: 587.33,
        D5s: 622.25,
        E5: 659.25,
        F5: 698.46,
        F5s: 739.99,
        G5: 783.99,
        G5s: 830.61,
        A5: 880.00,
        A5s: 932.33,
        B5: 987.77,
      }
      SCORE = [
        { frequency: :C5, duration: 0.5 },
        { frequency: :C5, duration: 0.5 },
        { frequency: :D5, duration: 0.5 },
        { frequency: :D5, duration: 0.5 },
        { frequency: :C5, duration: 0.5 },
        { frequency: :C5, duration: 0.5 },
        { frequency: :E5, duration: 0.5 },
        { frequency: :E5, duration: 0.5 },

        { frequency: :C5, duration: 0.5 },
        { frequency: :C5, duration: 0.5 },
        { frequency: :D5, duration: 0.5 },
        { frequency: :D5, duration: 0.5 },
        { frequency: :C5, duration: 0.5 },
        { frequency: :C5, duration: 0.5 },
        { frequency: :E5, duration: 0.5 },
        { frequency: :E5, duration: 0.5 },

        { frequency: :C5, duration: 0.5 },
        { frequency: :C5, duration: 0.5 },
        { frequency: :D5, duration: 0.5 },
        { frequency: :D5, duration: 0.5 },
        { frequency: :C5, duration: 0.5 },
        { frequency: :C5, duration: 0.5 },
        { frequency: :E5, duration: 0.5 },
        { frequency: :E5, duration: 0.5 },

        { frequency: :C5, duration: 1.0 },
        { frequency: :G4, duration: 1.0 },
        { frequency: :A4, duration: 1.0 },
        { frequency: :B4, duration: 1.0 },
      ]

      def generate
        process
        sample = if @current_note_sample_count < (@samples_per_note * STACCATO_RATIO)
          @generator.generate
        else
          0.0
        end
        increment_current_note_sample_count
        sample
      end

      def sample_rate
        @generator.sample_rate
      end

      private

      def initialize
        @bpm = BPM
        @notes = SCORE
        @current_note_index = 0
        @current_note_sample_count = 0
        @generator = SquareOscillator.new
        change_frequency
      end

      def process
        if @current_note_sample_count >= @samples_per_note
          @current_note_index += 1
          @current_note_sample_count = 0
          if @current_note_index >= @notes.size
            @current_note_index -= @notes.size
          end
          change_frequency
        end
      end

      def current_note
        @notes[@current_note_index]
      end

      def change_frequency
        quarter_duration = 60.0 / @bpm
        @samples_per_note = (@generator.sample_rate * quarter_duration * current_note[:duration]).to_i
        @generator.frequency = NOTES[current_note[:frequency]]
      end

      def increment_current_note_sample_count
        @current_note_sample_count += 1
      end
    end
  end
end
