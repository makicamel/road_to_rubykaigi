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
        [5, 13, '🧍 Hold -> 🚶‍➡️ Walk -> 🤸 Jump!'],
        [5, 14, "#{CalibrationSampler::PHASE_SECONDS}s each"],
      ],
      clear_instructions: [
        [5, 13, ' ' * 30],
        [5, 14, ' ' * 30],
      ],
      countdown:    [5, 8, 'Starting in %d...'],
      countdown_clear: [5, 8, ' ' * 20],
      done_static:  [5, 6, 'Static: %.6f (%d samples)'],
      done_walk:    [5, 7, 'Walk:   %.3f Hz (%d samples)'],
      done_jump:    [5, 8, 'Jump:   %.3f g (%d samples)'],
      done_return:  [5, 10, '[Enter/ESC] return'],
      not_connected: [
        [5, 6, 'Sensor not connected.'],
        [5, 7, 'Connect the sensor and try again.'],
        [5, 10, '[Enter/ESC] return'],
      ],
    }.freeze

    def display
      if Config.serial? && !File.exist?(Config.serial_port)
        enter_not_connected
      else
        Config.signal_source.start
        enter_intro
      end
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
      if @results.empty? && Config.signal_source.queue.empty?
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

      @results[@current_key] = {
        intensities: @sampler.intensities,
        cadences: @sampler.cadences,
        raw_samples: @sampler.raw_samples,
        sampling_rate_hz: @sampler.sampling_rate_hz,
      }
      @remaining_keys.shift

      if @remaining_keys.empty?
        enter_done
      else
        enter_collect
      end
    end

    def enter_done
      @state = :done
      result = CalibrationResult.from_samples(**@results)
      result.save
      ANSI.clear
      draw MESSAGES[:title],
           format_line(MESSAGES[:done_static], result.continuation_threshold, result.static_sample_count),
           format_line(MESSAGES[:done_walk], result.walk_cadence, result.walk_cadence_sample_count),
           format_line(MESSAGES[:done_jump], result.jump_v_max, result.jump_sample_count),
           MESSAGES[:done_return]
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
