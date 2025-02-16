module RoadToRubykaigi
  class Effects
    def update
      @effects.reject!(&:expired?)
    end

    def heart(x, y)
      @effects << HeartEffect.new(x,y)
    end

    def to_a
      @effects.to_a
    end

    private

    def initialize
      @effects = []
    end
  end

  class HeartEffect
    DURATION = 1.0
    SYMBOL = "\e[31m♥\e[0m"

    def update
      elapsed = Time.now - @start_time
      @y = (@y - elapsed).to_i
    end

    def render
      "\e[#{@y};#{@x}H" + SYMBOL
    end

    def expired?
      (Time.now - @start_time) >= DURATION
    end

    private

    def initialize(x, y)
      @x = x
      @y = y
      @start_time = Time.now
    end
  end
end
