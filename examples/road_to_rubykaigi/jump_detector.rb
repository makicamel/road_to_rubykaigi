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
  #
  # Sliding window is stored in a pre-allocated RingBuffer of [time,
  # vertical_acceleration] slots, to avoid per-tick Hash/Array allocations.
  class JumpDetector
    LOADED_THRESHOLD = 0.20         # vertical_acceleration above this counts as "loaded" (body under extra g-load)
    LOADED_MIN_SECONDS = 0.2       # loaded span qualifying as squat hold
    TAKEOFF_SLOPE_MAX = -1.0        # g/s — fall slope indicating takeoff turnover
    SLOPE_WINDOW_SECONDS = 0.08
    LOADED_END_GRACE_SECONDS = 0.15 # allow fire shortly past the span's last above-threshold point

    COOLDOWN_SECONDS = 0.8          # min gap between consecutive fires (covers takeoff→landing)
    SAMPLE_BUFFER_SECONDS = 1.2     # retain samples long enough to cover an elongated squat hold
    MIN_SAMPLES_FOR_ANALYSIS = 5    # slope + hold both need a few samples to be meaningful

    CAPACITY = 80 # SAMPLE_BUFFER_SECONDS × 50Hz = 60 plus safety margin
    # Slot layout: [time, vertical_acceleration]
    TIME_INDEX = 0
    VERTICAL_ACCELERATION_INDEX = 1

    def initialize(gravity:)
      @gravity = gravity
      @gravity_magnitude = Math.sqrt(gravity[0] ** 2 + gravity[1] ** 2 + gravity[2] ** 2)
      @samples = RingBuffer.new(CAPACITY) { [nil, 0.0] }
      @last_jump_time = nil
      @last_hold_seconds = 0.0
      @last_slope = 0.0
    end

    def detect(x, y, z, now)
      slot = @samples.write
      slot[TIME_INDEX] = now
      slot[VERTICAL_ACCELERATION_INDEX] = vertical_acceleration(x, y, z)
      cutoff = now - SAMPLE_BUFFER_SECONDS
      while !@samples.empty? && @samples.first[TIME_INDEX] < cutoff
        @samples.shift
      end

      if !buffer_ready? || !squat_takeoff? || cooling_down?(now)
        false
      else
        @last_jump_time = now
        true
      end
    end

    def latest_vertical_acceleration
      @samples.empty? ? 0.0 : @samples.last[VERTICAL_ACCELERATION_INDEX]
    end
    def latest_hold_seconds = @last_hold_seconds
    def latest_slope = @last_slope

    private

    def vertical_acceleration(x, y, z)
      projection = (-x * @gravity[0] + y * @gravity[1] + z * @gravity[2]) / @gravity_magnitude
      projection - @gravity_magnitude
    end

    def buffer_ready? = @samples.size >= MIN_SAMPLES_FOR_ANALYSIS
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
      size = @samples.size
      loaded_end_offset = nil
      i = size - 1
      while i >= 0
        if @samples.at(i)[VERTICAL_ACCELERATION_INDEX] > LOADED_THRESHOLD
          loaded_end_offset = i
          break
        end
        i -= 1
      end
      return 0.0 unless loaded_end_offset
      loaded_end_time = @samples.at(loaded_end_offset)[TIME_INDEX]
      # Too long past the span's end — no longer just after the turnover
      return 0.0 if @samples.last[TIME_INDEX] - loaded_end_time > LOADED_END_GRACE_SECONDS

      pre_load_offset = nil
      i = loaded_end_offset - 1
      while i >= 0
        if @samples.at(i)[VERTICAL_ACCELERATION_INDEX] <= LOADED_THRESHOLD
          pre_load_offset = i
          break
        end
        i -= 1
      end
      if pre_load_offset
        loaded_begin_offset = pre_load_offset + 1
        loaded_begin_time = @samples.at(loaded_begin_offset)[TIME_INDEX]
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
      end_slot = @samples.last
      end_time = end_slot[TIME_INDEX]
      end_vertical_acceleration = end_slot[VERTICAL_ACCELERATION_INDEX]
      cutoff = end_time - SLOPE_WINDOW_SECONDS
      begin_slot = nil
      i = @samples.size - 1
      while i >= 0
        if @samples.at(i)[TIME_INDEX] <= cutoff
          begin_slot = @samples.at(i)
          break
        end
        i -= 1
      end
      return 0.0 unless begin_slot

      elapsed_seconds = end_time - begin_slot[TIME_INDEX]
      if elapsed_seconds <= 0
        0.0
      else
        (end_vertical_acceleration - begin_slot[VERTICAL_ACCELERATION_INDEX]) / elapsed_seconds
      end
    end

  end
end
