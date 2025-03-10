module RoadToRubykaigi
  class ScoreBoard
    def increment
      @score += 1
    end

    def render
      "Score: #{@score}".ljust(10).rjust(Map::VIEWPORT_WIDTH)
    end

    def render_clear_result
      [ANSI::BLUE + "CLEAR!" + ANSI::DEFAULT_TEXT_COLOR, "Score: #{@score}", "Time: #{result_time} seconds"].map.with_index do |message, i|
        ANSI::RESULT_DATA[i] + "  #{message}  "
      end.join
    end

    def render_game_over_result
      [ANSI::RED + "Game Over" + ANSI::DEFAULT_TEXT_COLOR, "Score: #{@score}", "Time: #{result_time} seconds"].map.with_index do |message, i|
        ANSI::RESULT_DATA[i] + "  #{message}  "
      end.join
    end

    private

    def initialize
      @score = 0
      @start_time = Time.now
    end

    def result_time
      (Time.now - @start_time).round(2)
    end
  end
end
