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
      return 0.0 if @recent_magnitudes.size < MIN_SAMPLES_FOR_LOCAL_MAXIMUM

      magnitudes = @recent_magnitudes.map { |entry| entry[:magnitude] }
      magnitudes_total = 0.0
      magnitudes.each { |magnitude| magnitudes_total += magnitude }
      mean = magnitudes_total / magnitudes.size
      step_count = 0
      last_step_time = nil
      (1...(@recent_magnitudes.size - 1)).each do |i|
        time = @recent_magnitudes[i][:time]
        magnitude = @recent_magnitudes[i][:magnitude]
        prev_magnitude = @recent_magnitudes[i - 1][:magnitude]
        next_magnitude = @recent_magnitudes[i + 1][:magnitude]
        is_local_maximum = magnitude > prev_magnitude && magnitude > next_magnitude
        above_mean = magnitude > mean # only count bumps stronger than the average
        enough_gap_from_last_step = last_step_time.nil? || (time - last_step_time) >= MIN_STEP_INTERVAL_SECONDS
        if is_local_maximum && above_mean && enough_gap_from_last_step
          step_count += 1
          last_step_time = time
        end
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

    def buffer_sample(sample)
      now = Time.now
      @samples << { time: now, sample: sample }
      window_start = now - BUFFER_SECONDS
      @samples.shift while @samples.first[:time] < window_start
      @step_cadence.record(sample)
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

    # Sub-window containing samples from the last `seconds`, for continuation detection.
    def tail(seconds:)
      return SignalWindow.new([]) if @samples.empty?
      cutoff = @samples.last[:time] - seconds
      SignalWindow.new(@samples.select { |entry| entry[:time] >= cutoff })
    end

    private

    def initialize(samples = [])
      @samples = samples
      @step_cadence = StepCadence.new
    end

    def axis_variance(index)
      values = @samples.map { |entry| entry[:sample][index] }
      values_total = 0.0
      values.each { |value| values_total += value }
      mean = values_total / values.size
      squared_diff_total = 0.0
      values.each { |value| squared_diff_total += (value - mean) ** 2 }
      squared_diff_total / values.size
    end
  end
end
