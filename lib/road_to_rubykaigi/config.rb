require 'singleton'
require 'forwardable'

module RoadToRubykaigi
  class Config
    include Singleton

    CONFIG_FILE = '.road_to_rubykaigi'

    class << self
      extend Forwardable
      def_delegators :instance, :signal_server?, :debug?, :project_root
    end

    def initialize
      @settings = load
    end

    def signal_server?
      @settings['SIGNAL_SERVER']
    end

    def debug?
      @settings['DEBUG']
    end

    def project_root
      __dir__.sub('lib/road_to_rubykaigi', '')
    end

    private

    def load
      config_path = File.join(project_root, CONFIG_FILE)
      return {} unless File.exist?(config_path)

      File.readlines(config_path, chomp: true)
        .reject { |line| line.strip.empty? || line.strip.start_with?('#') }
        .each_with_object({}) do |line, hash|
          key, value = line.split('=')
          hash[key.strip] = value.strip
        end
    end
  end
end
