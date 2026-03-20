require 'webrick'

module RoadToRubykaigi
  class SignalServer
    PORT = 2026
    ENDPOINT = '/road_to_rubykaigi'

    def start
      Thread.new { build_server.start }
    end

    private

    def initialize
      log_file = Config.debug? ? File.join(Config.project_root, 'tmp/signal_server.log') : File.open(File::NULL, 'w')
      @logger = WEBrick::Log.new(log_file)
    end

    def build_server
      server = WEBrick::HTTPServer.new(
        Port: PORT,
        Logger: @logger,
        AccessLog: [],
      )
      server.mount_proc(ENDPOINT) { |req, res| handle(req, res) }
      server
    end

    def handle(req, res)
      res['Access-Control-Allow-Origin'] = '*'
      res['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
      @logger.info("#{req.request_method} #{req.path} #{req.query}")
      res.status = 200
    end
  end
end
