module RoadToRubykaigi
  class SignalWindow
    BUFFER_SECONDS = 0.5
    READY_FILL_RATIO = 0.8 # window must be 80% filled (by time) before considered ready

    StepCadence = Data.define(:recent_magnitudes) do
      WINDOW_SECONDS = 2.0
      MIN_STEP_INTERVAL_SECONDS = 0.15 # min gap between steps (caps cadence at ~6.7Hz)
      MIN_SAMPLES_FOR_LOCAL_MAXIMUM = 3 # need prev/current/next to detect a local maximum

      def record(sample)
        magnitude = Math.sqrt(sample[0] ** 2 + sample[1] ** 2 + sample[2] ** 2)
        now = Time.now
        recent_magnitudes << { time: now, magnitude: magnitude }
        window_start = now - WINDOW_SECONDS
        recent_magnitudes.shift while recent_magnitudes.first[:time] < window_start
      end

      # Step cadence in Hz: count of local maxima in the recent magnitudes divided
      # by the window duration. Walking produce one peak per footstrike, so cadence tracks step frequency.
      def hz
        return 0.0 if recent_magnitudes.size < MIN_SAMPLES_FOR_LOCAL_MAXIMUM

        magnitudes = recent_magnitudes.map { |entry| entry[:magnitude] }
        mean = magnitudes.sum / magnitudes.size
        step_count = 0
        last_step_time = nil
        (1...(recent_magnitudes.size - 1)).each do |i|
          time = recent_magnitudes[i][:time]
          magnitude = recent_magnitudes[i][:magnitude]
          prev_magnitude = recent_magnitudes[i - 1][:magnitude]
          next_magnitude = recent_magnitudes[i + 1][:magnitude]
          is_local_maximum = magnitude > prev_magnitude && magnitude > next_magnitude
          above_mean = magnitude > mean # only count bumps stronger than the average
          enough_gap_from_last_step = last_step_time.nil? || (time - last_step_time) >= MIN_STEP_INTERVAL_SECONDS
          if is_local_maximum && above_mean && enough_gap_from_last_step
            step_count += 1
            last_step_time = time
          end
        end

        duration = recent_magnitudes.last[:time] - recent_magnitudes.first[:time]
        return 0.0 if duration <= 0 # guard against division by zero (just in case)

        step_count / duration
      end

      def ready?
        return false if recent_magnitudes.size < MIN_SAMPLES_FOR_LOCAL_MAXIMUM
        (recent_magnitudes.last[:time] - recent_magnitudes.first[:time]) >= WINDOW_SECONDS * READY_FILL_RATIO
      end
    end

    def buffer_sample(sample)
      now = Time.now
      @samples << { time: now, sample: sample }
      window_start = now - BUFFER_SECONDS
      @samples.shift while @samples.first[:time] < window_start
      @step_cadence.record(sample)
    end

    def cadence_hz = @step_cadence.hz
    def cadence_ready? = @step_cadence.ready?

    def full?
      return false if @samples.size < 2
      (@samples.last[:time] - @samples.first[:time]) >= BUFFER_SECONDS * READY_FILL_RATIO
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
      sample = @samples.last[:sample]
      Math.sqrt(sample[0] ** 2 + sample[1] ** 2 + sample[2] ** 2)
    end

    # Raw [x, y, z] of the latest sample (before variance/intensity).
    def last_sample
      @samples.last[:sample]
    end

    # Signed vertical acceleration of the latest sample after removing
    # gravity. Positive = accelerating upward, negative = downward.
    def last_vertical_acceleration(gravity)
      sample = @samples.last[:sample]
      # Magnitude of the gravity reference vector (used to normalize the
      # projection below and as the resting 1g offset).
      gravity_magnitude = Math.sqrt(gravity[0] ** 2 + gravity[1] ** 2 + gravity[2] ** 2)
      # Sample projected onto the vertical axis, normalized to g units.
      projection = (sample[0] * gravity[0] + sample[1] * gravity[1] + sample[2] * gravity[2]) / gravity_magnitude
      # Subtract the resting offset.
      projection - gravity_magnitude
    end

    # Average absolute change in magnitude between consecutive samples.
    # Walking/running produce sharp footstrike impacts (high jerk),
    # while jumping produces smoother acceleration curves (low jerk).
    def mag_jerk
      mags = @samples.map { |entry| s = entry[:sample]; Math.sqrt(s[0] ** 2 + s[1] ** 2 + s[2] ** 2) }
      deltas = mags.each_cons(2).map { |a, b| (b - a).abs }
      deltas.sum / deltas.size
    end

    def full
      self
    end

    # Sub-window of the most recent n samples, for continuation detection.
    def tail(n)
      SignalWindow.new(@samples.last(n))
    end

    private

    def initialize(samples = [])
      @samples = samples
      @step_cadence = StepCadence.new(recent_magnitudes: [])
    end

    def axis_variance(index)
      values = @samples.map { |entry| entry[:sample][index] }
      mean = values.sum / values.size
      values.sum { |value| (value - mean) ** 2 } / values.size
    end
  end
end
