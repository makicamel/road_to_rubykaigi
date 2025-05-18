require 'ffi-portaudio'

module RoadToRubykaigi
  module Audio
    class AudioEngine < FFI::PortAudio::Stream
      include FFI::PortAudio

      def process(_input, output, framesPerBuffer, _timeInfo, _statusFlags, _userData)
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if @last_time
          ideal_interval = framesPerBuffer.to_f / @sample_rate
          actual_interval = now - @last_time
          @logger.info format(
            "framesPerBuffer: %4d, ideal: %.2f ms, actual: %.2f ms, drift: %.2f ms",
            framesPerBuffer, ideal_interval * 1000, actual_interval * 1000, (actual_interval - ideal_interval) * 1000,
          )
        end
        @last_time = now

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

      def mute
        @muted = true
      end

      def unmute
        @muted = false
      end

      private

      def initialize(bass_sequencer, melody_sequencer)
        @logger = Logger.new('log/audio_callback.log')
        @sample_rate = bass_sequencer.sample_rate
        @last_time = nil

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
