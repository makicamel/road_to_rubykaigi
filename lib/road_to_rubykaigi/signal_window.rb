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

    # Per-axis RMS spread. Same unit as motion_intensity but kept separate so
    # callers can compare how energy is distributed across axes.
    def axis_intensities
      [0, 1, 2].map { |index| Math.sqrt(axis_variance(index)) }
    end

    # Raw acceleration magnitude of the latest sample: sqrt(x² + y² + z²).
    def last_magnitude
      s = @samples.last
      Math.sqrt(s[0] ** 2 + s[1] ** 2 + s[2] ** 2)
    end

    # Average absolute change in magnitude between consecutive samples.
    # Walking/running produce sharp footstrike impacts (high jerk),
    # while jumping produces smoother acceleration curves (low jerk).
    def mag_jerk
      mags = @samples.map { |s| Math.sqrt(s[0] ** 2 + s[1] ** 2 + s[2] ** 2) }
      deltas = mags.each_cons(2).map { |a, b| (b - a).abs }
      deltas.sum / deltas.size
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
