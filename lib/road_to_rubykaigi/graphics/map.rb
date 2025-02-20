module RoadToRubykaigi
  module Graphics
    module Map
      FILE_PATH = "map.txt"

      def self.data
        File.read("#{__dir__}/#{FILE_PATH}").split("\n")
      end
    end
  end
end
