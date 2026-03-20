require 'webrick'

module RoadToRubykaigi
  class SignalServer
    PORT = 2026
    ENDPOINT = '/road_to_rubykaigi'

    def start
      server = build_server
      Thread.new { server.start }
    end

    private

    def build_server
      log_file = debug? ? File.join(project_root, 'tmp/signal_server.log') : File.open(File::NULL, 'w')
      server = WEBrick::HTTPServer.new(
        Port: PORT,
        Logger: WEBrick::Log.new(log_file),
        AccessLog: [],
      )
      server.mount_proc(ENDPOINT) { |req, res| handle(req, res) }
      server
    end

    def debug?
      config_path = File.join(project_root, '.road_to_rubykaigi')
      return false unless File.exist?(config_path)

      File.readlines(config_path, chomp: true).any? { |line| line.strip.match?(/\ADEBUG=/) }
    end

    def project_root
      __dir__.sub('lib/road_to_rubykaigi', '')
    end

    def handle(req, res)
      res['Access-Control-Allow-Origin'] = '*'
      res['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
      res.status = 200
    end
  end
end
