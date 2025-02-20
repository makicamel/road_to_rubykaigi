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

    def render(offset_x:)
      @effects.map do |effect|
        effect.render(offset_x: offset_x)
      end.join
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

    def render(offset_x:)
      "\e[#{@y};#{@x-offset_x}H" + self.class::SYMBOL
    end

    def expired?
      (Time.now - @start_time) >= self.class::DURATION
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
