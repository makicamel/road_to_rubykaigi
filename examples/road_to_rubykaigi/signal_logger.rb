module RoadToRubykaigi
  class SignalLogger
    Snapshot = Data.define(
      :sample, :state,
      :motion_intensity, :tail_intensity, :cadence_hz,
      :vertical_acceleration, :hold_seconds, :slope,
      :instant_speed, :smoothed_speed,
      :jump_fired,
    ) do
      def self.header
        "x,y,z,motion_intensity,tail_intensity,cadence_hz,vertical_acceleration,hold_seconds,slope,state,instant_speed,smoothed_speed,event"
      end

      def to_s
        x, y, z = sample.map { |value| value.round(6) }
        event = jump_fired ? 'jump_fired' : ''
        "#{x},#{y},#{z},#{motion_intensity.round(6)},#{tail_intensity.round(6)},#{cadence_hz.round(4)},#{vertical_acceleration.round(6)},#{hold_seconds.round(4)},#{slope.round(4)},#{state},#{instant_speed.round(4)},#{smoothed_speed.round(4)},#{event}"
      end
    end

    def log
      return unless @sig_log_io

      @sig_log_io.puts "#{Time.now.to_f},#{yield}"
    end

    private

    def initialize
      @sig_log_io = ENV['SIG_LOG'] == '1' ? open_sig_log_io : nil
    end

    def open_sig_log_io
      path = File.join(File.expand_path('../../tmp', __dir__), "sig_#{Time.now.strftime('%Y%m%d_%H%M')}.log")
      file = File.open(path, 'w')
      file.sync = true
      file.puts "t,#{Snapshot.header}"
      $stderr.puts "[SIG_LOG] writing to #{path}"
      file
    end
  end
end
