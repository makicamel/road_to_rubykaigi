# frozen_string_literal: true

require_relative "road_to_rubykaigi/version"
require_relative "road_to_rubykaigi/opening_screen"
require "io/console"

module RoadToRubykaigi
  class Error < StandardError; end

  def self.start
    OpeningScreen.new.display
  end
end
