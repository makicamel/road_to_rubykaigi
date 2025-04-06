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
          @audio_engine.add_source(@sources[action].sample)
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
        @sources[:game_over].first.tap do |source|
          @audio_engine.remove_source(@bass_sequencer)
          @audio_engine.remove_source(@melody_sequencer)
          @audio_engine.add_source(source)
          until source.finished?
            sleep 0.1
          end
        end
      end

      def walk
        now = Time.now
        if (now - @last_walk_time) >= WALK_SOUND_INTERVAL
          @audio_engine.add_source(@sources[:walk][@walk_index])
          @last_walk_time = now
          @walk_index = (@walk_index + 1) % @sources[:walk].size
        end
      end

      private

      def initialize
        @bass_sequencer = Audio::BassSequencer.new
        @melody_sequencer = Audio::MelodySequencer.new
        @fanfare_sequencer = Audio::FanfareSequencer.new
        @audio_engine = Audio::AudioEngine.new(@bass_sequencer, @melody_sequencer)
        @sources = SOUND_FILES
        @sources.each do |action, file_paths|
          @sources[action] = file_paths.map { |file_path| Audio::WavSource.new(file_path) }
        end
        @walk_index = 0
        @last_walk_time = Time.now - 1
      end
    end
  end
end
