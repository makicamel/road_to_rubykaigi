require_relative "road_to_rubykaigi/version"
require_relative "road_to_rubykaigi/ansi"
require_relative "road_to_rubykaigi/attack"
require_relative "road_to_rubykaigi/bonus"
require_relative "road_to_rubykaigi/collision_manager"
require_relative "road_to_rubykaigi/deadline"
require_relative "road_to_rubykaigi/effect"
require_relative "road_to_rubykaigi/enemy"
require_relative "road_to_rubykaigi/opening_screen"
require_relative "road_to_rubykaigi/game"
require_relative "road_to_rubykaigi/map"
require_relative "road_to_rubykaigi/player"
require_relative "road_to_rubykaigi/update_manager"
require "io/console"

module RoadToRubykaigi
  class Error < StandardError; end
  END_POSITION = Map.new.height + 2

  def self.start
    ANSI.cursor_off
    at_exit do
      print "\e[#{END_POSITION};1H"
      ANSI.cursor_on
    end

    OpeningScreen.new.display && Game.new.run
  end

  def self.debug
    @debug ||= []
  end

  def self.debug_add(string)
    @debug << "\e[#{END_POSITION+@debug.size};1H" + string
  end
end
