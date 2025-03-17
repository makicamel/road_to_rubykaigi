require 'singleton'

module RoadToRubykaigi
  module Manager
    class AudioManager
      include Singleton
      SOUND_FILES = {
        attack: %w[
          lib/road_to_rubykaigi/audio/attack_03.wav
          lib/road_to_rubykaigi/audio/attack_04.wav
          lib/road_to_rubykaigi/audio/attack_05.wav
        ],
        bonus: %w[lib/road_to_rubykaigi/audio/bonus.wav],
        crouch: %w[lib/road_to_rubykaigi/audio/crouch.wav],
        defeat: %w[lib/road_to_rubykaigi/audio/defeat.wav],
        game_over: %w[lib/road_to_rubykaigi/audio/game_over.wav],
        jump: %w[lib/road_to_rubykaigi/audio/jump.wav],
        laptop: %w[lib/road_to_rubykaigi/audio/laptop.wav],
        stun: %w[lib/road_to_rubykaigi/audio/stun.wav],
      }

      SOUND_FILES.keys.each do |action|
        define_method(action) {
          if macos?
            @players[action].sample.play
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
