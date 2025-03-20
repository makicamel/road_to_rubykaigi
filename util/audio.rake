require 'rake'

namespace :audio do
  desc "Normalize loudness. Separate multiple files with a space like: walk_01.wav walk_02.wav"
  task :normalize_loudness, [:target_files] do |t, args|
    require 'fileutils'
    require 'streamio-ffmpeg'

    target_lufs = -23
    true_peak = -1.5
    loudness_range = 11
    target_dir = "#{Dir.pwd}/lib/road_to_rubykaigi/audio"
    extensions = /\.(mp3|wav)$/i
    type = args[:target_files].strip.to_sym
    if type == :all
      backup_dir = "#{target_dir}_org"
      FileUtils.mkdir_p(backup_dir)
      target_files = Dir.glob(File.join(target_dir, "*")).select { |f| f.match? extensions }.tap do |files|
        files.each { |f| FileUtils.cp(f, backup_dir) }
      end
    else
      target_files = args[:target_files].split(" ").map { |filename| File.join(target_dir, filename) }
    end


    skips = []
    target_files.each do |filepath|
      unless (filepath =~ extensions) && File.exist?(filepath)
        next skips << filepath
      end

      puts "Processing: #{filepath}"
      extname = File.extname(filepath)
      basename = File.basename(filepath, extname)
      if type == :all
        output_filepath = filepath
        tmp_output_filepath = File.join(File.dirname(filepath), "tmp_#{basename}.wav")
      else
        output_filepath = File.join(File.dirname(filepath), "#{basename}_normalized.wav")
        tmp_output_filepath = output_filepath
      end

      FFMPEG::Movie.new(filepath).tap do |audio|
        audio.transcode(tmp_output_filepath, {
          audio_sample_rate: audio.audio_sample_rate,
          audio_bitrate: "#{(audio.bitrate.to_i / 1000).to_i}k",
          custom: [
            "-filter:a", "loudnorm=I=#{target_lufs}:TP=#{true_peak}:LRA=#{loudness_range}"
          ],
        })
      end
      if type == :all
        File.delete(filepath)
        File.rename(tmp_output_filepath, output_filepath)
      end
    end

    puts "Normalize loudness completed."
    puts "Skip: #{skips.join(", ")}" unless skips.empty?
  end
end
