module RoadToRubykaigi
  class Effects
    def update
      @effects.reject!(&:expired?)
    end

    def heart(x, y)
      @effects << HeartEffect.new(x, y)
    end

    def lightning(x, y)
      @effects << LightningEffect.new(x, y)
    end

    def build_buffer(offset_x:)
      buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
      @effects.each do |effect|
        bounding_box = effect.bounding_box
        relative_x = bounding_box[:x] - offset_x - 1
        relative_y = bounding_box[:y] - 1
        buffer[relative_y][relative_x] = effect.character
      end
      buffer
    end

    def to_a
      @effects.to_a
    end

    private

    def initialize
      @effects = []
    end
  end

  class Effect
    def update
      elapsed = Time.now - @start_time
      @y = (@y - elapsed).to_i
    end

    def character
      self.class::SYMBOL
    end

    def expired?
      (Time.now - @start_time) >= self.class::DURATION
    end

    def bounding_box
      { x: @x, y: @y, width: 1, height: 1 }
    end

    private

    def initialize(x, y)
      @x = x
      @y = y
      @start_time = Time.now
    end
  end

  class HeartEffect < Effect
    DURATION = 1.0
    SYMBOL = "\e[31m♥\e[0m"
  end

  class LightningEffect < Effect
    DURATION = 0.3
    SYMBOL = "\e[33m⚡︎\e[0m"

    def update
    end
  end
end
