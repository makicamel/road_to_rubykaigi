module RoadToRubykaigi
  module Graphics
    module Mask
      FILE_PATH = "mask.txt"
      MASK_CHARAS = "[╭─╮╰│╯┬◯╔═║╠╚╦╝╗╣┤┴┼├╽▐▗▖▌◻▥▞▟█▙◺◸┌┐┘└╨▝▘▄▜▛▀░▓]"
      def self.data
        File.read("#{__dir__}/#{FILE_PATH}").split("\n")
      end
    end
  end
end
