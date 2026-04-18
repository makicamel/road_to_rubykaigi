require 'singleton'
require 'forwardable'

module RoadToRubykaigi
  class Config
    include Singleton

    CONFIG_FILE = '.road_to_rubykaigi'
    DEFAULT_START_THRESHOLD = 0.025
    DEFAULT_CONTINUATION_THRESHOLD = 0.05

    class << self
      extend Forwardable
      def_delegators :instance, :input_source, :ble?, :serial?, :external_input?, :cycle_input_source,
                     :serial_port, :detect_serial_port!,
                     :signal_source, :debug?, :bgm_off?, :project_root,
                     :start_threshold, :continuation_threshold, :walk_cadence, :walk_intensity,
                     :gravity_vector, :jump_v_max, :save_calibration
    end

    INPUT_SOURCES = %i[ble serial].freeze
    INPUT_SOURCE_CYCLE = [nil, :ble, :serial].freeze

    def initialize
      @settings = load
    end

    def input_source
      value = @settings['INPUT_SOURCE']&.to_sym
      INPUT_SOURCES.include?(value) ? value : nil
    end

    def ble? = input_source == :ble
    def serial? = input_source == :serial
    def external_input? = !input_source.nil?

    def input_source=(value)
      @settings['INPUT_SOURCE'] = value.to_s
      save(['INPUT_SOURCE'])
    end

    def cycle_input_source
      current_index = INPUT_SOURCE_CYCLE.index(input_source) || 0
      self.input_source = INPUT_SOURCE_CYCLE[(current_index + 1) % INPUT_SOURCE_CYCLE.size]
      detect_serial_port! if serial?
    end

    def serial_port
      @settings['SERIAL_PORT'] || detect_serial_port
    end

    def detect_serial_port!
      return serial_port if File.exist?(serial_port)

      port = detect_serial_port
      if port
        @settings['SERIAL_PORT'] = port
        save(['SERIAL_PORT'])
      end
      port
    end

    def signal_source
      serial? ? SerialReader : GameServer
    end

    def debug?
      @settings['DEBUG']
    end

    def bgm_off?
      @settings['BGM_OFF']
    end

    def start_threshold
      (@settings['START_THRESHOLD'] || DEFAULT_START_THRESHOLD).to_f
    end

    def continuation_threshold
      (@settings['CONTINUATION_THRESHOLD'] || DEFAULT_CONTINUATION_THRESHOLD).to_f
    end

    def walk_cadence
      @settings['WALK_CADENCE']&.to_f
    end

    def walk_intensity
      @settings['WALK_INTENSITY']&.to_f
    end

    def gravity_vector
      value = @settings['GRAVITY']
      return nil unless value

      parts = value.split(',').map(&:to_f)
      parts.size == 3 ? parts : nil
    end

    def jump_v_max
      @settings['JUMP_V_MAX']&.to_f
    end

    def save_calibration(start_threshold:, continuation_threshold:, walk_cadence:, walk_intensity:,
                         gravity_vector: nil, jump_v_max: nil)
      @settings['START_THRESHOLD'] = start_threshold.to_s
      @settings['CONTINUATION_THRESHOLD'] = continuation_threshold.to_s
      @settings['WALK_CADENCE'] = walk_cadence.to_s
      @settings['WALK_INTENSITY'] = walk_intensity.to_s
      keys = %w[START_THRESHOLD CONTINUATION_THRESHOLD WALK_CADENCE WALK_INTENSITY]
      if gravity_vector
        @settings['GRAVITY'] = gravity_vector.join(',')
        keys << 'GRAVITY'
      end
      if jump_v_max
        @settings['JUMP_V_MAX'] = jump_v_max.to_s
        keys << 'JUMP_V_MAX'
      end
      save(keys)
    end

    def project_root
      __dir__.sub('lib/road_to_rubykaigi', '')
    end

    private

    def detect_serial_port
      Dir.glob('/dev/cu.usbserial-*').first
    end

    def config_path
      File.join(project_root, CONFIG_FILE)
    end

    def load
      return {} unless File.exist?(config_path)

      File.readlines(config_path, chomp: true)
        .reject { |line| line.strip.empty? || line.strip.start_with?('#') }
        .each_with_object({}) do |line, hash|
          key, value = line.split('=', 2)
          hash[key.strip] = value.strip if value
        end
    end

    def save(keys)
      File.copy_stream("#{config_path}.sample", config_path) unless File.exist?(config_path)

      lines = File.readlines(config_path, chomp: true)
      keys.each do |key|
        pattern = /\A\s*#?\s*#{key}\s*=/
        entry = "#{key}=#{@settings[key]}"
        index = lines.index { |line| line.match?(pattern) }
        index ? lines[index] = entry : lines << entry
        lines.reject! { |line| line.match?(pattern) && line != entry }
      end
      File.write(config_path, lines.join("\n") + "\n")
    end
  end
end
