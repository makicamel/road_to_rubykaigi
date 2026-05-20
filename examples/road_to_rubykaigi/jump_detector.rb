module RoadToRubykaigi
  # Detects squat-jumps from the accelerometer stream.
  #
  # Axis-agnostic: consumes the gravity-compensated vertical acceleration
  # instead of any single raw axis. vertical_acceleration = projection of the
  # sample onto the gravity vector, minus |gravity|. So rest = 0, upward
  # proper acceleration > 0, downward (or free fall) < 0.
  #
  # Rule: loaded hold + bottom turnover. Running strides briefly peak the
  # vertical acceleration above the loaded threshold at each footstrike.
  # A squat-jump holds it above the threshold noticeably longer. Fire at the
  # bottom of that span (slope becomes clearly negative), whether the signal
  # is still above the threshold or has just crossed back below.
  #
  # Firing at the bottom of the load (not at landing or at full takeoff)
  # minimizes latency.
  #
  # The loaded span must start from an up-crossing (a prior sample at or
  # below the threshold) inside the buffer. Otherwise a stationary sensor
  # reading near 0 could drift above threshold and accumulate an unbounded
  # "loaded hold" that passes the duration gate on its own.
  class JumpDetector
    LOADED_THRESHOLD = 0.20         # vertical_acceleration above this counts as "loaded" (body under extra g-load)
    LOADED_MIN_SECONDS = 0.2       # loaded span qualifying as squat hold
    TAKEOFF_SLOPE_MAX = -1.0        # g/s — fall slope indicating takeoff turnover
    SLOPE_WINDOW_SECONDS = 0.08
    LOADED_END_GRACE_SECONDS = 0.15 # allow fire shortly past the span's last above-threshold point

    COOLDOWN_SECONDS = 0.8          # min gap between consecutive fires (covers takeoff→landing)
    SAMPLE_BUFFER_SECONDS = 1.2     # retain samples long enough to cover an elongated squat hold
    MIN_SAMPLES_FOR_ANALYSIS = 5    # slope + hold both need a few samples to be meaningful

    def initialize(gravity:)
      @gravity = gravity
      @gravity_magnitude = Math.sqrt(gravity[0] ** 2 + gravity[1] ** 2 + gravity[2] ** 2)
      @times = []
      @vertical_accelerations = []
      @last_jump_time = nil
      @last_hold_seconds = 0.0
      @last_slope = 0.0
    end

    def detect(sample:)
      now = Time.now
      @times << now
      @vertical_accelerations << vertical_acceleration(sample)
      cutoff = now - SAMPLE_BUFFER_SECONDS
      while !@times.empty? && @times.first < cutoff
        @times.shift
        @vertical_accelerations.shift
      end

      if !buffer_ready? || !squat_takeoff? || cooling_down?(now)
        false
      else
        @last_jump_time = now
        true
      end
    end

    def latest_vertical_acceleration = @vertical_accelerations.empty? ? 0.0 : @vertical_accelerations.last
    def latest_hold_seconds = @last_hold_seconds
    def latest_slope = @last_slope

    private

    def vertical_acceleration(sample)
      projection = (-sample[0] * @gravity[0] + sample[1] * @gravity[1] + sample[2] * @gravity[2]) / @gravity_magnitude
      projection - @gravity_magnitude
    end

    def buffer_ready? = @times.size >= MIN_SAMPLES_FOR_ANALYSIS
    def cooling_down?(now) = @last_jump_time && (now - @last_jump_time) < COOLDOWN_SECONDS

    def squat_takeoff?
      @last_hold_seconds = last_loaded_hold_seconds
      @last_slope = last_slope

      if @last_hold_seconds < LOADED_MIN_SECONDS
        false
      else
        @last_slope <= TAKEOFF_SLOPE_MAX
      end
    end

    # Duration of the latest span where vertical_acceleration stayed
    # continuously above LOADED_THRESHOLD. Returns 0 if the span reaches the
    # buffer edge without a preceding below-threshold sample — that indicates
    # stationary state (signal hovering near 0 continuously), not an
    # oscillating stride.
    # The span may still be in progress (latest sample above threshold) or
    # just ended within the last sample — jumps launch fast enough that the
    # signal can skip from +1g to below threshold between consecutive samples.
    def last_loaded_hold_seconds
      loaded_end_idx = nil
      i = @vertical_accelerations.size - 1
      while i >= 0
        if @vertical_accelerations[i] > LOADED_THRESHOLD
          loaded_end_idx = i
          break
        end
        i -= 1
      end
      return 0.0 unless loaded_end_idx
      loaded_end_time = @times[loaded_end_idx]
      # Too long past the span's end — no longer just after the turnover
      return 0.0 if @times.last - loaded_end_time > LOADED_END_GRACE_SECONDS

      pre_load_idx = nil
      i = loaded_end_idx - 1
      while i >= 0
        if @vertical_accelerations[i] <= LOADED_THRESHOLD
          pre_load_idx = i
          break
        end
        i -= 1
      end
      if pre_load_idx
        loaded_begin_idx = pre_load_idx + 1
        loaded_begin_time = @times[loaded_begin_idx]
        loaded_end_time - loaded_begin_time
      else
        0.0
      end
    end

    # Slope (g/s) of vertical_acceleration over the last SLOPE_WINDOW_SECONDS,
    # measured as (latest - reference) / dt where reference is the newest
    # sample at or before the window cutoff. A clearly negative value means
    # the signal has peaked and started falling — the takeoff turnover.
    def last_slope
      end_time = @times.last
      end_vertical_acceleration = @vertical_accelerations.last
      cutoff = end_time - SLOPE_WINDOW_SECONDS
      begin_idx = nil
      i = @times.size - 1
      while i >= 0
        if @times[i] <= cutoff
          begin_idx = i
          break
        end
        i -= 1
      end
      return 0.0 unless begin_idx

      elapsed_seconds = end_time - @times[begin_idx]
      if elapsed_seconds <= 0
        0.0
      else
        (end_vertical_acceleration - @vertical_accelerations[begin_idx]) / elapsed_seconds
      end
    end

  end
end
