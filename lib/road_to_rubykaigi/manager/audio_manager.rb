require 'ffi'

module RoadToRubykaigi
  module Manager
    class AudioManager
      include Singleton
      SOUND_FILES = {
        jump: "lib/road_to_rubykaigi/audio/jump.wav",
      }

      SOUND_FILES.keys.each do |action|
        define_method(action) {
          if macos?
            Audio::AudioToolbox.AudioServicesPlaySystemSound(@sound_ids[action])
          end
        }
      end

      def dispose
        @sound_ids.each_value do |sound_id|
          if macos?
            Audio::AudioToolbox.AudioServicesDisposeSystemSoundID(sound_id)
          end
        end
      end

      private

      def initialize
        @sound_ids = SOUND_FILES

        if macos?
          require_relative "../audio/macos"

          @sound_ids.each do |action, file_path|
            @sound_ids[action] = register_system_sound_id(file_path)
          end
        end
      end

      def macos?
        @macos ||= RUBY_PLATFORM.match?(/darwin/)
      end

      def register_system_sound_id(file_path)
        cf_str = Audio::CoreFoundation.CFStringCreateWithCString(
          Audio::CoreFoundation::DefaultAllocator,
          file_path,
          Audio::CoreFoundation::UTF8Encoding,
        )
        return nil if cf_str.null?

        cf_url = Audio::CoreFoundation.CFURLCreateWithFileSystemPath(
          Audio::CoreFoundation::DefaultAllocator,
          cf_str,
          Audio::CoreFoundation::POSIXPathStyle,
          false, # isDirectory
        )
        Audio::CoreFoundation.CFRelease(cf_str)
        return nil if cf_url.null?

        sound_id_pointer = FFI::MemoryPointer.new(:uint32)
        os_status = Audio::AudioToolbox.AudioServicesCreateSystemSoundID(cf_url, sound_id_pointer)
        Audio::CoreFoundation.CFRelease(cf_url)
        unless os_status.zero?
          return warn "Failed to load sound #{file_path}: error code #{os_status}"
        end

        sound_id_pointer.read_uint32
      end
    end
  end
end
