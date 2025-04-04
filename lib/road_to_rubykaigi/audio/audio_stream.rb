require 'ffi-portaudio'

module RoadToRubykaigi
  module Audio
    module Phasor
      def sample_rate
        44_100
      end

      private

      def initialize
        frequency = 0
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

    class AudioStream < FFI::PortAudio::Stream
      include FFI::PortAudio

      def initialize(frame_size = 2**12)
        @note_sequencer = NoteSequencer.new
        @muted = false
        API.Pa_Initialize
        open(nil, output, @note_sequencer.sample_rate, frame_size)
        start

        at_exit do
          @muted = true
          sleep 0.5
          close
          API.Pa_Terminate
        end
      end

      def process(_input, output, framesPerBuffer, _timeInfo, _statusFlags, _userData)
        if @muted
          samples = Array.new(framesPerBuffer, 0)
        else
          samples = (0...framesPerBuffer).map { @note_sequencer.generate }
        end
        output.write_array_of_float(samples)
        :paContinue
      end

      private

      def output
        output = API::PaStreamParameters.new
        output[:device] = API.Pa_GetDefaultOutputDevice
        output[:suggestedLatency] = API.Pa_GetDeviceInfo(output[:device])[:defaultHighOutputLatency]
        output[:hostApiSpecificStreamInfo] = nil
        output[:channelCount] = 1 # monaural
        output[:sampleFormat] = API::Float32
        output
      end
    end
  end
end
