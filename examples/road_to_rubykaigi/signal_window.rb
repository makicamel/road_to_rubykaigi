module RoadToRubykaigi
  class StepCadence
    WINDOW_SECONDS = 2.0
    MIN_STEP_INTERVAL_SECONDS = 0.15 # min gap between steps (caps cadence at ~6.7Hz)
    MIN_SAMPLES_FOR_LOCAL_MAXIMUM = 3 # need prev/current/next to detect a local maximum
    READY_FILL_RATIO = 0.8 # window must be 80% filled (by time) before considered ready

    def initialize
      @recent_magnitudes = []
    end

    def record(x, y, z)
      magnitude = Math.sqrt(x ** 2 + y ** 2 + z ** 2)
      now = Time.now
      @recent_magnitudes << { time: now, magnitude: magnitude }
      window_start = now - WINDOW_SECONDS
      @recent_magnitudes.shift while @recent_magnitudes.first[:time] < window_start
    end

    # Step cadence in Hz: count of local maxima in the recent magnitudes divided
    # by the window duration. Walking produce one peak per footstrike, so cadence tracks step frequency.
    def hz
      size = @recent_magnitudes.size
      return 0.0 if size < MIN_SAMPLES_FOR_LOCAL_MAXIMUM

      magnitudes_total = 0.0
      i = 0
      while i < size
        magnitudes_total += @recent_magnitudes[i][:magnitude]
        i += 1
      end
      mean = magnitudes_total / size

      step_count = 0
      last_step_time = nil
      i = 1
      while i < size - 1
        magnitude = @recent_magnitudes[i][:magnitude]
        prev_magnitude = @recent_magnitudes[i - 1][:magnitude]
        next_magnitude = @recent_magnitudes[i + 1][:magnitude]
        is_local_maximum = magnitude > prev_magnitude && magnitude > next_magnitude
        above_mean = magnitude > mean # only count bumps stronger than the average
        time = @recent_magnitudes[i][:time]
        enough_gap_from_last_step = last_step_time.nil? || (time - last_step_time) >= MIN_STEP_INTERVAL_SECONDS
        if is_local_maximum && above_mean && enough_gap_from_last_step
          step_count += 1
          last_step_time = time
        end
        i += 1
      end

      duration = @recent_magnitudes.last[:time] - @recent_magnitudes.first[:time]
      return 0.0 if duration <= 0 # guard against division by zero (just in case)

      step_count / duration
    end

    def ready?
      return false if @recent_magnitudes.size < MIN_SAMPLES_FOR_LOCAL_MAXIMUM
      (@recent_magnitudes.last[:time] - @recent_magnitudes.first[:time]) >= WINDOW_SECONDS * READY_FILL_RATIO
    end
  end

  class SignalWindow
    BUFFER_SECONDS = 0.5
    READY_FILL_RATIO = 0.8 # window must be 80% filled (by time) before considered ready
    CADENCE_TRACKING_ENABLED = RUBY_ENGINE != "mruby"
    CAPACITY = 32 # 50Hz × 0.5s = 25 plus safety margin
    # Slot layout: [time, x, y, z]
    TIME_INDEX = 0
    X_INDEX = 1
    Y_INDEX = 2
    Z_INDEX = 3

    def buffer_sample(x, y, z)
      slot = @samples.write
      now = Time.now
      slot[TIME_INDEX] = now
      slot[X_INDEX] = x
      slot[Y_INDEX] = y
      slot[Z_INDEX] = z
      window_start = now - BUFFER_SECONDS
      while !@samples.empty? && @samples.first[TIME_INDEX] < window_start
        @samples.shift
      end
      @step_cadence.record(x, y, z) if CADENCE_TRACKING_ENABLED
      @full_motion_intensity = nil
    end

    def cadence_hz = @step_cadence.hz
    def cadence_ready? = @step_cadence.ready?

    def full?
      return false if @samples.size < 2
      (@samples.last[TIME_INDEX] - @samples.first[TIME_INDEX]) >= BUFFER_SECONDS * READY_FILL_RATIO
    end

    # Returns how far samples in the window spread from their mean position
    # (RMS distance across all 3 axes), computed over the whole @samples.
    # Cached until @samples changes.
    def full_motion_intensity
      @full_motion_intensity ||= Math.sqrt(axis_variance(X_INDEX) + axis_variance(Y_INDEX) + axis_variance(Z_INDEX))
    end

    def last_x = @samples.last[X_INDEX]
    def last_y = @samples.last[Y_INDEX]
    def last_z = @samples.last[Z_INDEX]

    # Computes motion intensity over the subset of @samples newer than
    # (last_sample_time - seconds).
    def tail_motion_intensity(seconds:)
      return 0.0 if @samples.empty?
      cutoff = @samples.last[TIME_INDEX] - seconds
      start_offset = 0
      size = @samples.size
      while start_offset < size && @samples.at(start_offset)[TIME_INDEX] < cutoff
        start_offset += 1
      end
      Math.sqrt(
        sub_axis_variance(X_INDEX, start_offset, size) +
        sub_axis_variance(Y_INDEX, start_offset, size) +
        sub_axis_variance(Z_INDEX, start_offset, size)
      )
    end

    private

    def initialize
      @samples = RingBuffer.new(CAPACITY) { [nil, 0.0, 0.0, 0.0] }
      @step_cadence = StepCadence.new
    end

    def axis_variance(axis_index)
      sub_axis_variance(axis_index, 0, @samples.size)
    end

    def sub_axis_variance(axis_index, start_offset, end_offset)
      count = end_offset - start_offset
      return 0.0 if count <= 0
      values_total = 0.0
      i = start_offset
      while i < end_offset
        values_total += @samples.at(i)[axis_index]
        i += 1
      end
      mean = values_total / count
      squared_diff_total = 0.0
      i = start_offset
      while i < end_offset
        diff = @samples.at(i)[axis_index] - mean
        squared_diff_total += diff * diff
        i += 1
      end
      squared_diff_total / count
    end
  end
end
