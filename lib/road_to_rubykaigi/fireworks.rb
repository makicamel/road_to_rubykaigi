module RoadToRubykaigi
  class Fireworks
    START_X = 465
    DURATION_SECOND = 0.1

    def shoot
      @shooting = true
    end

    def update
      return unless shooting?
      if finished?
        return @game_manager.finish
      end

      if Time.now - @last_frame_time >= DURATION_SECOND
        @frame_index += 1
        @last_frame_time = Time.now
      end
    end

    def build_buffer(offset_x:)
      return [] if !shooting? || finished?

      buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
      relative_x = @x - offset_x
      relative_y = @y
      current_frame.each_with_index do |row, i|
        row.chars.each_with_index do |character, j|
          next if character == " "
          next if (relative_x + j).abs > Map::VIEWPORT_WIDTH
          buffer[relative_y+i][relative_x+j] = character
        end
      end
      buffer
    end

    private

    def initialize(game_manager)
      @x = START_X
      @y = 3
      @game_manager = game_manager
      @start_time = Time.now
      @frame_index = 0
      @last_frame_time = Time.now
      @shooting = false
      @frames = RoadToRubykaigi::Graphics::Fireworks.data
    end

    def shooting?
      @shooting
    end

    def finished?
      @frame_index > @frames.size - 2
    end

    def current_frame
      @frames[@frame_index]
    end
  end
end
