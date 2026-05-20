module RoadToRubykaigi
  class StepCadence
    WINDOW_SECONDS = 2.0
    MIN_STEP_INTERVAL_SECONDS = 0.15 # min gap between steps (caps cadence at ~6.7Hz)
    MIN_SAMPLES_FOR_LOCAL_MAXIMUM = 3 # need prev/current/next to detect a local maximum
    READY_FILL_RATIO = 0.8 # window must be 80% filled (by time) before considered ready

    def initialize
      @recent_magnitudes = []
    end

    def record(sample)
      magnitude = Math.sqrt(sample[0] ** 2 + sample[1] ** 2 + sample[2] ** 2)
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
    CADENCE_TRACKING_ENABLED = RUBY_ENGINE != "mruby/c"

    def buffer_sample(sample)
      now = Time.now
      @samples << { time: now, sample: sample }
      window_start = now - BUFFER_SECONDS
      @samples.shift while @samples.first[:time] < window_start
      @step_cadence.record(sample) if CADENCE_TRACKING_ENABLED
      @full_motion_intensity = nil
    end

    def cadence_hz = @step_cadence.hz
    def cadence_ready? = @step_cadence.ready?

    def full?
      return false if @samples.size < 2
      (@samples.last[:time] - @samples.first[:time]) >= BUFFER_SECONDS * READY_FILL_RATIO
    end

    # Returns how far samples in the window spread from their mean position
    # (RMS distance across all 3 axes), computed over the whole @samples.
    # Cached until @samples changes.
    def full_motion_intensity
      @full_motion_intensity ||= Math.sqrt(axis_variance(0) + axis_variance(1) + axis_variance(2))
    end

    # Raw [x, y, z] of the latest sample (before variance/intensity).
    def last_sample
      @samples.last[:sample]
    end

    # Computes motion intensity over the subset of @samples newer than
    # (last_sample_time - seconds).
    def tail_motion_intensity(seconds:)
      return 0.0 if @samples.empty?
      cutoff = @samples.last[:time] - seconds
      start_idx = 0
      size = @samples.size
      while start_idx < size && @samples[start_idx][:time] < cutoff
        start_idx += 1
      end
      Math.sqrt(
        sub_axis_variance(0, start_idx, size) +
        sub_axis_variance(1, start_idx, size) +
        sub_axis_variance(2, start_idx, size)
      )
    end

    private

    def initialize(samples = [])
      @samples = samples
      @step_cadence = StepCadence.new
    end

    def axis_variance(index)
      sub_axis_variance(index, 0, @samples.size)
    end

    def sub_axis_variance(index, start_idx, end_idx)
      count = end_idx - start_idx
      return 0.0 if count <= 0
      values_total = 0.0
      i = start_idx
      while i < end_idx
        values_total += @samples[i][:sample][index]
        i += 1
      end
      mean = values_total / count
      squared_diff_total = 0.0
      i = start_idx
      while i < end_idx
        diff = @samples[i][:sample][index] - mean
        squared_diff_total += diff * diff
        i += 1
      end
      squared_diff_total / count
    end
  end
end
