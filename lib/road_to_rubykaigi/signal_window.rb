module RoadToRubykaigi
  class SignalWindow
    SIZE = 5

    def buffer_sample(sample)
      @samples = (@samples + [sample]).last(SIZE)
    end

    def full?
      @samples.size == SIZE
    end

    # Returns how far samples in the window spread from their mean position
    # (RMS distance across all 3 axes).
    def motion_intensity
      Math.sqrt(axis_variance(0) + axis_variance(1) + axis_variance(2))
    end

    # Sub-window of the most recent n samples, for peak detection.
    def tail(n)
      SignalWindow.new(@samples.last(n))
    end

    private

    def initialize(samples = [])
      @samples = samples
    end

    def axis_variance(index)
      values = @samples.map { |sample| sample[index] }
      mean = values.sum / values.size
      values.sum { |value| (value - mean) ** 2 } / values.size
    end
  end
end
