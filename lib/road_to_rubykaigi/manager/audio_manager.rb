require 'singleton'

module RoadToRubykaigi
  module Manager
    class AudioManager
      include Singleton
      SOUND_FILES = {
        jump: %w[lib/road_to_rubykaigi/audio/jump.wav],
        attack: %w[
          lib/road_to_rubykaigi/audio/attack_03.wav
          lib/road_to_rubykaigi/audio/attack_04.wav
          lib/road_to_rubykaigi/audio/attack_05.wav
        ],
      }

      SOUND_FILES.keys.each do |action|
        define_method(action) {
          if macos?
            Audio::MacOS.play(@players[action].sample)
          end
        }
      end

      private

      def initialize
        @players = SOUND_FILES

        if macos?
          require_relative "../audio/macos"

          @players.each do |action, file_paths|
            @players[action] = file_paths.map { |file_path| Audio::MacOS.build_player(file_path) }
          end
        end
      end

      def macos?
        @macos ||= RUBY_PLATFORM.match?(/darwin/)
      end
    end
  end
end
