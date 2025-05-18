require 'singleton'

module RoadToRubykaigi
  module Manager
    class AudioManager
      include Singleton
      SOUND_FILES = {
        attack: %w[
          lib/road_to_rubykaigi/audio/wav/attack_03.wav
          lib/road_to_rubykaigi/audio/wav/attack_04.wav
          lib/road_to_rubykaigi/audio/wav/attack_05.wav
        ],
        bonus: %w[lib/road_to_rubykaigi/audio/wav/bonus.wav],
        crouch: %w[lib/road_to_rubykaigi/audio/wav/crouch.wav],
        defeat: %w[lib/road_to_rubykaigi/audio/wav/defeat.wav],
        game_over: %w[lib/road_to_rubykaigi/audio/wav/game_over.wav],
        jump: %w[lib/road_to_rubykaigi/audio/wav/jump.wav],
        laptop: %w[lib/road_to_rubykaigi/audio/wav/laptop.wav],
        stun: %w[lib/road_to_rubykaigi/audio/wav/stun.wav],
        walk: %w[
          lib/road_to_rubykaigi/audio/wav/walk_01.wav
          lib/road_to_rubykaigi/audio/wav/walk_02.wav
        ],
      }
      WALK_SOUND_INTERVAL = 0.25

      SOUND_FILES.keys.each do |action|
        define_method(action) {
          if macos?
            @players[action].sample.play
          else
            @audio_engine.add_source(@sources[action].sample)
          end
        }
      end

      def fanfare
        @audio_engine.mute
        @audio_engine.remove_source(@bass_sequencer)
        @audio_engine.remove_source(@melody_sequencer)
        @audio_engine.unmute
        @audio_engine.add_source(@fanfare_sequencer)
      end

      def fanfare_finished?
        @fanfare_sequencer.finished?
      end

      def game_over
        if macos?
          @players[:game_over].sample.tap do |player|
            player.play
            while player.playing?
              sleep 0.1
            end
          end
        else
          @sources[:game_over].first.tap do |source|
            @audio_engine.remove_source(@bass_sequencer)
            @audio_engine.remove_source(@melody_sequencer)
            @audio_engine.add_source(source)
            until source.finished?
              sleep 0.1
            end
          end
        end
      end

      def walk
        if macos?
          now = Time.now
          if (now - @last_walk_time) >= WALK_SOUND_INTERVAL
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

            @players[:walk][@walk_index].play
            diff = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
            @logger.info format("Audio::MacOS#play took %.3f ms", diff * 1000)

            @last_walk_time = now
            @walk_index = (@walk_index + 1) % @players[:walk].size
          end
        else
          now = Time.now
          if (now - @last_walk_time) >= WALK_SOUND_INTERVAL
            @audio_engine.add_source(@sources[:walk][@walk_index])
            @last_walk_time = now
            @walk_index = (@walk_index + 1) % @sources[:walk].size
          end
        end
      end

      private

      def initialize
        @bass_sequencer = Audio::BassSequencer.new
        @melody_sequencer = Audio::MelodySequencer.new
        @fanfare_sequencer = Audio::FanfareSequencer.new
        @audio_engine = Audio::AudioEngine.new(@bass_sequencer, @melody_sequencer)
        @sources = SOUND_FILES
        dir = __dir__.sub("lib/road_to_rubykaigi/manager", "")
        if macos?
          require_relative "../audio/macos"
          @players = SOUND_FILES
          @players.each do |action, file_paths|
            @players[action] = file_paths.map { |file_path| Audio::MacOS.build_player(file_path) }
          end
          @logger = Logger.new("log/wave_logger.log")
        else
          @sources.each do |action, file_paths|
            @sources[action] = file_paths.map { |file_path| Audio::WavSource.new(dir + file_path) }
          end
        end
        @walk_index = 0
        @last_walk_time = Time.now - 1
      end

      def macos?
        @macos ||= RUBY_PLATFORM.match?(/darwin/)
      end
    end
  end
end
