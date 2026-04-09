require 'singleton'
require 'webrick'

module RoadToRubykaigi
  class GameServer
    include Singleton

    HOST = 'http://127.0.0.1'
    PORT = 2026
    ENDPOINT = '/road_to_rubykaigi'

    class << self
      extend Forwardable
      def_delegators :instance, :start, :queue
    end

    attr_reader :queue

    def start
      @queue.clear
      return if @server

      @server = build_server
      @thread = Thread.new { @server.start }
      at_exit do
        @server.shutdown rescue nil
        @thread.kill
      end
      open_controller
    end

    private

    def open_controller
      url = "#{HOST}:#{PORT}/controller.html"
      command =
        case RbConfig::CONFIG['host_os']
        when /darwin/ then ['open', url]
        when /mswin|mingw|cygwin/ then ['cmd', '/c', 'start', '', url]
        else ['xdg-open', url]
        end
      pid = spawn(*command, out: File::NULL, err: File::NULL)
      Process.detach(pid)
    rescue
      # best effort: don't crash the server if the browser can't be opened
    end

    def initialize
      @queue = Thread::Queue.new
      log_file = Config.debug? ? File.join(Config.project_root, 'tmp/game_server.log') : File.open(File::NULL, 'w')
      @logger = WEBrick::Log.new(log_file)
    end

    def build_server
      server = WEBrick::HTTPServer.new(
        Port: PORT,
        Logger: @logger,
        AccessLog: [],
      )
      server.mount_proc(ENDPOINT) { |req, res| handle(req, res) }

      public_dir = File.join(Config.project_root, 'public')
      server.mount('/', WEBrick::HTTPServlet::FileHandler, public_dir)

      server
    end

    def handle(req, res)
      res['Access-Control-Allow-Origin'] = '*'
      res['Access-Control-Allow-Methods'] = 'GET, OPTIONS'

      @logger.info("#{req.request_method} #{req.path} #{req.query}")
      @queue.push(req.query) unless req.query.empty?

      res.status = 200
    end
  end
end
