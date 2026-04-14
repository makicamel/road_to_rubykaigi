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
      def_delegators :instance, :game_server?, :debug?, :bgm_off?, :project_root,
                     :start_threshold, :continuation_threshold, :walk_intensity, :save_calibration
    end

    def initialize
      @settings = load
    end

    def game_server?
      @settings['GAME_SERVER']
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

    def walk_intensity
      @settings['WALK_INTENSITY']&.to_f
    end

    def save_calibration(start_threshold:, continuation_threshold:, walk_intensity:)
      @settings['START_THRESHOLD'] = start_threshold.to_s
      @settings['CONTINUATION_THRESHOLD'] = continuation_threshold.to_s
      @settings['WALK_INTENSITY'] = walk_intensity.to_s
      save(%w[START_THRESHOLD CONTINUATION_THRESHOLD WALK_INTENSITY])
    end

    def project_root
      __dir__.sub('lib/road_to_rubykaigi', '')
    end

    private

    def config_path
      File.join(project_root, CONFIG_FILE)
    end

    def load
      return {} unless File.exist?(config_path)

      File.readlines(config_path, chomp: true)
        .reject { |line| line.strip.empty? || line.strip.start_with?('#') }
        .each_with_object({}) do |line, hash|
          key, value = line.split('=')
          hash[key.strip] = value.strip
        end
    end

    def save(keys)
      File.copy_stream("#{config_path}.sample", config_path) unless File.exist?(config_path)

      lines = File.readlines(config_path, chomp: true)
      keys.each do |key|
        index = lines.index { |line| line.match?(/\A\s*#?\s*#{key}\s*=/) }
        entry = "#{key}=#{@settings[key]}"
        index ? lines[index] = entry : lines << entry
      end
      File.write(config_path, lines.join("\n") + "\n")
    end
  end
end
