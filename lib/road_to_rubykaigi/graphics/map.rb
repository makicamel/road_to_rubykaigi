module RoadToRubykaigi
  module Graphics
    module Map
      FILE_PATH = "map.txt"
      DEMO_FILE_PATH = "demo-map.txt"

      def self.data
        File.read("#{__dir__}/#{file_path}").split("\n")
      end

      def self.file_path
        @file_path ||= RoadToRubykaigi.demo? ? DEMO_FILE_PATH : FILE_PATH
      end
    end
  end
end
