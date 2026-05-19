module RoadToRubykaigi
  class SignalConfig
    CONFIG_FILE = '.road_to_rubykaigi'
    DEFAULT_START_THRESHOLD = 0.025
    DEFAULT_CONTINUATION_THRESHOLD = 0.05

    attr_reader :start_threshold, :continuation_threshold,
                :walk_cadence, :walk_intensity,
                :gravity_vector, :jump_v_max

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
      path = ["#{ENV['HOME']}/#{CONFIG_FILE}", "./#{CONFIG_FILE}"].find { |p| File.exist?(p) }
      return {} unless path

      result = {}
      File.open(path, "r") do |file|
        file.read.split("\n").each do |line|
          stripped = line.strip
          next if stripped.empty? || stripped.start_with?('#')
          key, value = stripped.split('=', 2)
          result[key.strip] = value.strip if value
        end
      end
      result
    end

    def parse_gravity_vector(value)
      return nil unless value
      parts = value.split(',').map(&:to_f)
      parts.size == 3 ? parts : nil
    end
  end
end
