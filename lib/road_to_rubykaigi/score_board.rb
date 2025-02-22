module RoadToRubykaigi
  class ScoreBoard
    def increment
      @score += 1
    end

    def render
      "Score: #{@score}".ljust(10).rjust(Map::VIEWPORT_WIDTH)
    end

    private

    def initialize
      @score = 0
    end
  end
end
