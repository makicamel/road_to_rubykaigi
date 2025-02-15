require_relative "road_to_rubykaigi/version"
require_relative "road_to_rubykaigi/ansi"
require_relative "road_to_rubykaigi/bonus"
require_relative "road_to_rubykaigi/opening_screen"
require_relative "road_to_rubykaigi/game"
require_relative "road_to_rubykaigi/map"
require_relative "road_to_rubykaigi/player"
require "io/console"

module RoadToRubykaigi
  class Error < StandardError; end
  END_POSITION = Map.new.height + 1

  def self.start
    ANSI.cursor_off
    at_exit do
      print "\e[#{END_POSITION};1H"
      ANSI.cursor_on
    end

    OpeningScreen.new.display && Game.new.run
  end
end
