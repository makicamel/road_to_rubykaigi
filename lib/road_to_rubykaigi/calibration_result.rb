module RoadToRubykaigi
  CalibrationResult = Data.define(
    :start_threshold,
    :continuation_threshold,
    :walk_cadence,
    :walk_cadence_sample_count,
    :walk_intensity,
    :gravity_vector,
    :jump_v_max,
    :static_sample_count,
    :jump_sample_count,
  ) do
    # Derives calibrated values from per-phase collected samples.
    def self.from_samples(static:, walk:, jump:)
      # Use p95 rather than max so a single stray spike during "still" doesn't
      # inflate every downstream threshold.
      sorted_static = static[:intensities].sort
      noise_ceiling = sorted_static[(sorted_static.size * 0.95).floor] || 0.0
      # Noise ceiling * 2.5 as the threshold separating noise from walking.
      # Stays above noise even in short-window valleys between steps.
      #   2.5 is an empirical factor derived from real calibration data.
      start_threshold = noise_ceiling * 2.5
      # Continuation uses a short window (fast stop detection) which is noise-sensitive,
      # so use a higher threshold for noise tolerance.
      continuation_threshold = noise_ceiling * 5.0
      gravity_vector = mean_vector(static[:raw_samples])
      new(
        start_threshold:,
        continuation_threshold:,
        walk_cadence:     median(walk[:cadences]), # Median walking step cadence in Hz, representing individual step frequency.
        walk_intensity:   median(walk[:intensities]), # Used by the intensity-boost path that lifts in-place running (elevated intensity, walk-level cadence).
        gravity_vector:,
        jump_v_max:       max_vertical_acceleration(jump[:raw_samples], gravity_vector),

        static_sample_count: static[:intensities].size,
        walk_cadence_sample_count: walk[:cadences].size,
        jump_sample_count: jump[:raw_samples].size,
      )
    end

    def self.median(values)
      sorted = values.sort
      sorted[sorted.size / 2] || 0.0
    end

    # Averaged [x, y, z] of the resting accelerometer, used as the gravity reference.
    def self.mean_vector(samples)
      samples.transpose.map { |values| values.sum / values.size }
    end

    # Max upward acceleration (in g, gravity subtracted) observed across jump samples.
    def self.max_vertical_acceleration(samples, gravity)
      gravity_magnitude = Math.sqrt(gravity[0] ** 2 + gravity[1] ** 2 + gravity[2] ** 2)
      samples.map { |sample|
        (sample[0] * gravity[0] + sample[1] * gravity[1] + sample[2] * gravity[2]) / gravity_magnitude - gravity_magnitude
      }.max || 0.0
    end

    def save
      Config.save_calibration(
        start_threshold: start_threshold.round(6),
        continuation_threshold: continuation_threshold.round(6),
        walk_cadence: walk_cadence.round(6),
        walk_intensity: walk_intensity.round(6),
        gravity_vector: gravity_vector.map { |value| value.round(6) },
        jump_v_max: jump_v_max.round(6),
      )
    end
  end
end
