require 'ffi-portaudio'

module RoadToRubykaigi
  module Audio
    class AudioEngine < FFI::PortAudio::Stream
      include FFI::PortAudio

      def process(_input, output, framesPerBuffer, _timeInfo, _statusFlags, _userData)
        samples = Array.new(framesPerBuffer, 0.0)

        unless @muted
          @sources.each do |source|
            framesPerBuffer.times do |i|
              sample = source.generate * source.gain
              samples[i] += sample
            end
            remove_source(source) if source.finished?
          end
        end

        output.write_array_of_float(samples)
        :paContinue
      end

      def add_source(source)
        @sources << source.rewind
      end

      def remove_source(source)
        @sources.delete(source)
      end

      private

      def initialize(bass_sequencer, melody_sequencer)
        frame_size = 2 ** 12 # 4096
        @sources = [bass_sequencer, melody_sequencer]
        @muted = false
        API.Pa_Initialize
        open(nil, output, bass_sequencer.sample_rate, frame_size)
        start

        at_exit do
          @muted = true
          sleep 0.5
          close
          API.Pa_Terminate
        end
      end

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
