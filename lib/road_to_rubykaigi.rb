require_relative "road_to_rubykaigi/version"
require_relative "road_to_rubykaigi/ansi"
require_relative "road_to_rubykaigi/audio/audio_engine"
require_relative "road_to_rubykaigi/audio/oscillator"
require_relative "road_to_rubykaigi/audio/sequencer"
require_relative "road_to_rubykaigi/audio/wav_source"
require_relative "road_to_rubykaigi/event_dispatcher"
require_relative "road_to_rubykaigi/fireworks"
require_relative "road_to_rubykaigi/game"
require_relative "road_to_rubykaigi/map"
require_relative "road_to_rubykaigi/opening_screen"
require_relative "road_to_rubykaigi/score_board"
require_relative "road_to_rubykaigi/manager/audio_manager"
require_relative "road_to_rubykaigi/manager/collision_manager"
require_relative "road_to_rubykaigi/manager/drawing_manager"
require_relative "road_to_rubykaigi/manager/game_manager"
require_relative "road_to_rubykaigi/manager/physics_engine"
require_relative "road_to_rubykaigi/manager/update_manager"
require_relative "road_to_rubykaigi/sprite/sprite"
require_relative "road_to_rubykaigi/sprite/attack"
require_relative "road_to_rubykaigi/sprite/bonus"
require_relative "road_to_rubykaigi/sprite/deadline"
require_relative "road_to_rubykaigi/sprite/effect"
require_relative "road_to_rubykaigi/sprite/enemy"
require_relative "road_to_rubykaigi/sprite/player"
require_relative "road_to_rubykaigi/graphics/fireworks"
require_relative "road_to_rubykaigi/graphics/mask"
require_relative "road_to_rubykaigi/graphics/map"
require_relative "road_to_rubykaigi/graphics/player"
require "io/console"

module RoadToRubykaigi
  class Error < StandardError; end
  END_POSITION = Map::VIEWPORT_HEIGHT + 2

  def self.start(game_mode = :normal)
    ANSI.cursor_off
    at_exit do
      print "\e[#{END_POSITION};1H"
      ANSI.cursor_on
    end

    @game_mode = game_mode
    if demo?
      Game.new.run
    else
      OpeningScreen.new.display && Game.new.run
    end
  end

  def self.demo?
    @game_mode != :normal
  end

  def self.debug
    @debug ||= []
  end

  def self.debug_add(string)
    debug << "\e[#{END_POSITION+debug.size};1H" + string
  end
end
