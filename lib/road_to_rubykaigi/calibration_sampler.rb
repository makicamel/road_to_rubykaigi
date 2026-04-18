module RoadToRubykaigi
  class CalibrationSampler
    PHASE_SECONDS = 5

    attr_reader :intensities, :cadences, :raw_samples, :intensity

    def tick
      Config.signal_source.drain do |data|
        sample = parse_sample(data)
        next unless sample
        @window.buffer_sample(sample)
        @raw_samples << sample
      end
      return unless @window.full?
      @intensity = @window.motion_intensity
      @intensities << @intensity
      @cadences << @window.cadence_hz if @window.cadence_ready?
    end

    def finished?
      elapsed >= PHASE_SECONDS
    end

    def remaining
      PHASE_SECONDS - elapsed
    end

    def progress
      (elapsed / PHASE_SECONDS.to_f).clamp(0.0, 1.0)
    end

    private

    def initialize
      @window = SignalWindow.new
      @intensities = []
      @cadences = []
      @raw_samples = []
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
