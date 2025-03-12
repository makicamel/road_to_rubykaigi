require 'singleton'

module RoadToRubykaigi
  module Manager
    class AudioManager
      include Singleton
      SOUND_FILES = {
        jump: "lib/road_to_rubykaigi/audio/jump.wav",
        attack: "lib/road_to_rubykaigi/audio/attack.wav",
      }

      SOUND_FILES.keys.each do |action|
        define_method(action) {
          if macos?
            Audio::MacOS.play(@players[action])
          end
        }
      end

      private

      def initialize
        @players = SOUND_FILES

        if macos?
          require_relative "../audio/macos"

          @players.each do |action, file_path|
            @players[action] = Audio::MacOS.build_player(file_path)
          end
        end
      end

      def macos?
        @macos ||= RUBY_PLATFORM.match?(/darwin/)
      end
    end
  end
end
