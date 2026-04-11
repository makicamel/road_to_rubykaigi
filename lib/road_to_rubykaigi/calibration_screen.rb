module RoadToRubykaigi
  class CalibrationScreen
    COUNTDOWN_FROM = 5

    MESSAGES = {
      title: [5, 3, '=== Sensor Calibration ==='],
      intro: [
        [5, 10, '[Enter/Space] start'],
        [5, 11, '[ESC]         return'],
      ],
      cancel: [5, 11, '[ESC] cancel'],
      instructions: [
        [5, 13, "Hold still for #{CalibrationSampler::PHASE_SECONDS}s"],
        [5, 14, "Then walk for #{CalibrationSampler::PHASE_SECONDS}s"],
      ],
      clear_instructions: [
        [5, 13, ' ' * 30],
        [5, 14, ' ' * 30],
      ],
      countdown:    [5, 8, 'Starting in %d...'],
      countdown_clear: [5, 8, ' ' * 20],
      done_static:  [5, 6, 'Static: %.6f (%d samples)'],
      done_walk:    [5, 7, 'Walk:   %.6f (%d samples)'],
      done_return:  [5, 10, '[Enter/ESC] return'],
      not_connected: [
        [5, 6, 'Sensor not connected.'],
        [5, 7, 'Connect the sensor and try again.'],
        [5, 10, '[Enter/ESC] return'],
      ],
    }.freeze

    def display
      GameServer.start
      enter_intro
      $stdin.raw do
        loop do
          case tick
          when :done then return
          end
          sleep Manager::GameManager::FRAME_RATE
        end
      end
    end

    private

    def tick
      action = read_action
      if action == :cancel
        if @state == :intro || @state == :done
          return :done
        else
          enter_intro && return
        end
      end

      case @state
      when :intro     then action == :proceed && enter_countdown
      when :countdown then tick_countdown
      when :collect   then tick_collect
      when :done      then action == :proceed && enter_intro
      end
    end

    def enter_intro
      @state = :intro
      @results = {}
      @remaining_keys = CalibrationBar.states
      ANSI.clear
      draw MESSAGES[:title], *MESSAGES[:intro], *MESSAGES[:instructions]
    end

    def enter_countdown
      @state = :countdown
      @countdown_remaining = COUNTDOWN_FROM
      @countdown_last_tick = nil
      ANSI.clear
      draw MESSAGES[:title], MESSAGES[:cancel], *MESSAGES[:instructions]
    end

    def tick_countdown
      now = Time.now
      @countdown_last_tick ||= now

      if now - @countdown_last_tick >= 1.0
        @countdown_remaining -= 1
        @countdown_last_tick = now
      end

      if @countdown_remaining <= 0
        draw MESSAGES[:countdown_clear]
        enter_collect
      else
        draw format_line(MESSAGES[:countdown], @countdown_remaining)
      end
    end

    def enter_not_connected
      @state = :done
      ANSI.clear
      draw MESSAGES[:title], *MESSAGES[:not_connected]
    end

    def enter_collect
      if @results.empty? && GameServer.queue.empty?
        enter_not_connected && return
      end

      @state = :collect
      @current_key = @remaining_keys.first
      @sampler = CalibrationSampler.new
      @bar = CalibrationBar.new(@sampler, state: @current_key)
      draw *MESSAGES[:clear_instructions]
    end

    def tick_collect
      @sampler.tick
      draw *@bar.render

      return unless @sampler.finished?

      @results[@current_key] = @sampler.samples
      @remaining_keys.shift

      if @remaining_keys.empty?
        enter_done
      else
        enter_collect
      end
    end

    def enter_done
      @state = :done
      peak_threshold, walk_intensity = save_calibration
      ANSI.clear
      draw MESSAGES[:title],
           format_line(MESSAGES[:done_static], peak_threshold, @results[:static].size),
           format_line(MESSAGES[:done_walk], walk_intensity, @results[:walk].size),
           MESSAGES[:done_return]
    end

    def save_calibration
      # Noise ceiling * 2.5 as the threshold separating noise from walking.
      # Stays above noise even in short-window valleys between steps.
      #   2.5 is an empirical factor derived from real calibration data.
      peak_threshold = @results[:static].max * 2.5
      # Median walking motion_intensity, representing individual walking strength.
      walk_sorted = @results[:walk].sort
      walk_intensity = walk_sorted[walk_sorted.size / 2]
      Config.save_calibration(peak_threshold: peak_threshold.round(6), walk_intensity: walk_intensity.round(6))
      [peak_threshold, walk_intensity]
    end

    def format_line(line, *args)
      x, y, template = line
      [x, y, format(template, *args)]
    end

    def read_action
      case $stdin.read_nonblock(3, exception: false)
      when ANSI::ETX then raise Interrupt
      when ANSI::ENTER, ANSI::LF, ANSI::SPACE then :proceed
      when ANSI::ESC then :cancel
      end
    end

    def draw(*lines)
      lines.each { |x, y, text| print "\e[#{y};#{x}H#{text}" }
      $stdout.flush
    end
  end
end
