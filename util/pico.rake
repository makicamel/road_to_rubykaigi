require 'rake'

namespace :pico do
  ROAD_FILES = %w[
    ring_buffer
    signal_window
    jump_detector
    signal_config
    signal_interpreter
  ]
  ROAD_DIR = 'examples/road_to_rubykaigi/'
  CONCAT_PATH = 'tmp/road_to_rubykaigi.rb'

  desc 'Concatenate road_to_rubykaigi/*.rb into a single .rb with one module wrapper'
  task :concat do
    File.open(CONCAT_PATH, 'w') do |out|
      out.puts 'module RoadToRubykaigi'
      ROAD_FILES.each do |name|
        body = File.read("#{ROAD_DIR}/#{name}.rb")
        body = body.sub(/\Amodule RoadToRubykaigi\s*\n/, '').sub(/\nend\s*\z/, "\n")
        out.write body
        out.puts
      end
      out.puts 'end'
    end
    puts "Concatenated #{CONCAT_PATH} (#{File.size(CONCAT_PATH)} bytes)"
  end

  APP_PATH = 'examples/accelerometer.rb'
  APP_BUNDLED_PATH = 'tmp/app_bundled.rb'

  desc 'Bundle road_to_rubykaigi classes + accelerometer.rb into a single app file'
  task bundle_app: :concat do
    File.open(APP_BUNDLED_PATH, 'w') do |out|
      out.write File.read(CONCAT_PATH)
      out.puts
      out.write File.read(APP_PATH)
    end
    puts "Bundled #{APP_BUNDLED_PATH} (#{File.size(APP_BUNDLED_PATH)} bytes)"
  end

  CONFIG_PATH = '.road_to_rubykaigi'
  REMOTE_CONFIG_PATH = '/home/.road_to_rubykaigi'

  desc 'Send the bundled app to /home/app.mrb (and .road_to_rubykaigi if present)'
  task send_app: :bundle_app do
    port = Dir.glob('/dev/cu.usbmodem*').sort.first
    raise 'No /dev/cu.usbmodem* device found' if port.nil?
    pairs = []
    if File.exist?(CONFIG_PATH)
      pairs << "#{CONFIG_PATH} #{REMOTE_CONFIG_PATH}"
    else
      warn "[!] #{CONFIG_PATH} not found; skipping config upload"
    end
    pairs << "#{APP_BUNDLED_PATH} /home/app.mrb"
    sh "ruby bin/send_file.rb --mrb #{port} #{pairs.join(' ')}"
  end
end
