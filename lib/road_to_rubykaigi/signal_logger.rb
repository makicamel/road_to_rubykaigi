module RoadToRubykaigi
  class SignalLogger
    def initialize
      @sig_log_io = ENV['SIG_LOG'] == '1' ? open_sig_log_io : nil
    end

    def log(state:, full_motion_intensity:, tail_motion_intensity:, cadence_hz:,
                   instant_speed_ratio:, smoothed_speed_ratio:, last_sample:)
      return unless @sig_log_io

      x, y, z = last_sample.map { |value| value.round(6) }
      @sig_log_io.puts "#{Time.now.to_f},#{full_motion_intensity.round(6)},#{tail_motion_intensity.round(6)},#{cadence_hz.round(4)},#{instant_speed_ratio.round(4)},#{smoothed_speed_ratio.round(4)},#{state},#{x},#{y},#{z}"
    end

    def log_cue(phase, text)
      return unless @sig_log_io

      @sig_log_io.puts "[cue] t=#{Time.now.to_f} phase=#{phase} #{text}"
    end

    def log_jump(message)
      return unless ENV['JUMP_LOG'] == '1'

      $stderr.puts "[JumpDetector] #{Time.now.to_f} #{message}"
    end

    private

    def open_sig_log_io
      path = File.join(File.expand_path('../../tmp', __dir__), "sig_#{Time.now.strftime('%Y%m%d_%H%M')}.log")
      file = File.open(path, 'w')
      file.sync = true
      file.puts "t,full,tail,cadence,instant,speed,state,x,y,z"
      $stderr.puts "[SIG_LOG] writing to #{path}"
      file
    end
  end
end
