module RoadToRubykaigi
  module Graphics
    module Mask
      FILE_PATH = "mask.txt"
      DEMO_FILE_PATH = "demo-mask.txt"
      MASK_CHARAS = "[╭─╮╰│╯┬◯╔═║╠╚╦╝╗╣┤┴┼├╽▐▗▖▌◻▥▞▟█▙◺◸┌┐┘└╨▝▘▄▜▛▀░▓]"

      def self.data
        File.read("#{__dir__}/#{file_path}").split("\n")
      end

      def self.file_path
        @file_path ||= [RoadToRubykaigi.version, RoadToRubykaigi.demo? ? DEMO_FILE_PATH : FILE_PATH].join('/')
      end
    end
  end
end
