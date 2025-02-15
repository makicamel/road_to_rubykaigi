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

    def render
      @map.map.with_index do |line, i|
        "\e[#{i+1};1H" + line
      end.join
    end
  end
end
