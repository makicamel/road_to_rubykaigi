module RoadToRubykaigi
    class Map
      attr_reader :width, :height

      def initialize
        @map = [
          "####################################################",
          "#                                                  #",
          "#                                                  #",
          "#                                                  #",
          "#                                                  #",
          "#                                                  #",
          "#                                                  #",
          "#                                                  #",
          "#                                                  #",
          "#                                                  #",
          "#                                                  #",
          "####################################################",
        ]
        @height = @map.size
        @width  = @map.first.size
      end

      def draw
        str = @map.map.with_index do |line, i|
          "\e[#{i+1};1H" + line
        end.join("\n")
        puts str
      end
    end
  end
