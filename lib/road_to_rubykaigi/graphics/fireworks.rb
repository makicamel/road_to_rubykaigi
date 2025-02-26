module RoadToRubykaigi
  module Graphics
    module Fireworks
      FILE_PATH = "fireworks.txt"

      def self.data
        File
          .read("#{__dir__}/#{FILE_PATH}")
          .tr("-", " ")
          .split("\n")
          .each_slice(16)
          .to_a
      end
    end
  end
end
