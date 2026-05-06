module RoadToRubykaigi
  class SignalConfig
    CONFIG_FILE = '.road_to_rubykaigi'
    DEFAULT_PATH = File.expand_path("../../#{CONFIG_FILE}", __dir__)
    DEFAULT_START_THRESHOLD = 0.025
    DEFAULT_CONTINUATION_THRESHOLD = 0.05

    attr_reader :start_threshold, :continuation_threshold,
                :walk_cadence, :walk_intensity,
                :gravity_vector, :jump_v_max

    def self.instance
      @instance ||= new
    end

    def self.invalidate
      @instance = nil
    end

    def self.start_threshold = instance.start_threshold
    def self.continuation_threshold = instance.continuation_threshold
    def self.walk_cadence = instance.walk_cadence
    def self.walk_intensity = instance.walk_intensity
    def self.gravity_vector = instance.gravity_vector
    def self.jump_v_max = instance.jump_v_max

    private

    def initialize
      settings = load
      @start_threshold = settings['START_THRESHOLD']&.to_f || DEFAULT_START_THRESHOLD
      @continuation_threshold = settings['CONTINUATION_THRESHOLD']&.to_f || DEFAULT_CONTINUATION_THRESHOLD
      @walk_cadence = settings['WALK_CADENCE']&.to_f
      @walk_intensity = settings['WALK_INTENSITY']&.to_f
      @gravity_vector = parse_gravity_vector(settings['GRAVITY'])
      @jump_v_max = settings['JUMP_V_MAX']&.to_f
    end

    def load
      return {} unless File.exist?(DEFAULT_PATH)

      File.readlines(DEFAULT_PATH, chomp: true)
        .reject { |line| line.strip.empty? || line.strip.start_with?('#') }
        .each_with_object({}) do |line, hash|
          key, value = line.split('=', 2)
          hash[key.strip] = value.strip if value
        end
    end

    def parse_gravity_vector(value)
      return nil unless value
      parts = value.split(',').map(&:to_f)
      parts.size == 3 ? parts : nil
    end
  end
end
