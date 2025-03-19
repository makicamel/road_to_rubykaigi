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
        walk: %w[
          lib/road_to_rubykaigi/audio/walk_01.wav
          lib/road_to_rubykaigi/audio/walk_02.wav
        ],
      }
      WALK_SOUND_INTERVAL = 0.12

      SOUND_FILES.keys.each do |action|
        define_method(action) {
          if macos?
            @players[action].sample.play
          end
        }
      end

      def game_over
        if macos?
          @players[:game_over].sample.tap do |player|
            player.play
            while player.playing?
              sleep 0.1
            end
          end
        end
      end

      def walk
        if macos?
          now = Time.now
          if (now - @last_walk_time) >= WALK_SOUND_INTERVAL
            @players[:walk][@walk_index].play
            @last_walk_time = now
            @walk_index = (@walk_index + 1) % @players[:walk].size
          end
        end
      end

      private

      def initialize
        @players = SOUND_FILES

        if macos?
          require_relative "../audio/macos"

          @players.each do |action, file_paths|
            @players[action] = file_paths.map { |file_path| Audio::MacOS.build_player(file_path) }
          end
          @walk_index = 0
          @last_walk_time = Time.now - 1
        end
      end

      def macos?
        @macos ||= RUBY_PLATFORM.match?(/darwin/)
      end
    end
  end
end
