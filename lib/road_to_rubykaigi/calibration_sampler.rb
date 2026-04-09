module RoadToRubykaigi
  class CalibrationSampler
    PHASE_SECONDS = 3

    attr_reader :samples, :intensity

    def tick
      GameServer.drain do |data|
        sample = parse_sample(data)
        @window.buffer_sample(sample) if sample
      end
      return unless @window.full?
      @intensity = @window.motion_intensity
      @samples << @intensity
    end

    def finished?
      elapsed >= PHASE_SECONDS
    end

    def remaining
      PHASE_SECONDS - elapsed
    end

    private

    def initialize
      @window = SignalWindow.new
      @samples = []
      @intensity = 0.0
      @started_at = Time.now
    end

    def elapsed
      Time.now - @started_at
    end

    def parse_sample(data)
      return nil unless %w[x y z].all? { |key| data.key?(key) }
      [data['x'].to_f, data['y'].to_f, data['z'].to_f]
    end
  end
end
