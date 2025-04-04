require 'rake'

namespace :audio do
  desc "Output audio information"
  task :info do
    require "streamio-ffmpeg"
    require "csv"
    require "json"

    target_dir = "#{Dir.pwd}/lib/road_to_rubykaigi/audio"
    output_csv = "audio_info.csv"
    extensions = /\.(mp3|wav)$/i

    CSV.open(output_csv, "w", write_headers: true, headers: %w[Filename Artist SampleRate(kHz) Duration(seconds) BitRate(kb/s) Channels IntegratedLoudness(LUFS) TruePeak(dBTP)]) do |csv|
      Dir.glob(File.join(target_dir, "*")).each do |filepath|
        next unless filepath.match?(extensions)

        artist, sample_rate, duration, bitrate, channels, integrated_loudness, true_peak_value = nil
        [FFMPEG.ffprobe_binary, "-i", filepath, *%w[-print_format json -show_entries format_tags=artist,author -show_format -show_streams -show_error]].tap do |command|
          audio = JSON.parse(`#{command.join " "}`)
          artist = audio.dig("format", "tags", "artist") || audio.dig("format", "tags", "author") || ""
          sample_rate = audio["streams"][0]["sample_rate"].to_i / 1000.0
          channels = audio["streams"][0]["channels"]
          duration = audio["format"]["duration"]
          bitrate = audio["format"]["bit_rate"].to_i / 1000.0
        end

        ["ffmpeg", "-i", filepath, *%w(-filter_complex "ebur128=peak=true" -f null - 2>&1)].tap do |command|
          result = `#{command.join " "}`
          integrated_loudness = result.scan(/Integrated loudness:\s*\n\s*I:\s*(-[\d.]+)\s*LUFS/).flatten.first
          true_peak_value = result.scan(/True peak:\s*\n\s+Peak:\s+(-[\d.]+)\s*dBFS/).flatten.first
        end

        csv << [File.basename(filepath), artist, sample_rate, duration, bitrate, channels, integrated_loudness, true_peak_value]
      end
    end

    puts "Output audio information to #{output_csv}"
  end

  desc "Add artist name to metadata"
  task :add_artist do
    require "streamio-ffmpeg"

    dir = "#{Dir.pwd}/lib/road_to_rubykaigi/audio/"
    filename = "stun.wav"
    extname = File.extname(filename)
    input_file = dir + filename
    output_file = dir + File.basename(filename, extname) + "_1" + extname
    artist_name = "PANICPUMPKIN / pansound.com/panicpumpkin"

    FFMPEG::Movie.new(input_file).tap do |audio|
      audio.transcode(output_file, {
        audio_sample_rate: audio.audio_sample_rate,
        audio_bitrate: "#{(audio.bitrate.to_i / 1000).to_i}k",
        custom: ["-metadata", "artist=#{artist_name}"],
      })
    end
    puts "Generated #{output_file} with the artist name."
  end

  desc "Conversion mp3 files to wav files"
  task :conversion_from_mp3_to_wav do
    require "streamio-ffmpeg"

    dir = "/path/to/file/"
    site = "example.com/"
    file = "walk_01"
    start_second = 0.1625
    duration = 2.12
    suffix = 1
    input_file = "#{dir}#{site}#{file}.mp3"
    output_file = "#{dir}#{site}#{file}_#{suffix}.wav"

    FFMPEG::Movie.new(input_file).tap do |audio|
      audio.transcode(output_file, {
        audio_codec: "pcm_s16le",
        audio_sample_rate: audio.audio_sample_rate,
        audio_bitrate: "#{(audio.bitrate.to_i / 1000).to_i}k",
        custom: ["-ss", start_second.to_s, "-t", duration.to_s]
      })
    end

    puts "Conversion completed."
  end

  desc "Normalize loudness. Separate multiple files with a space like: walk_01.wav walk_02.wav"
  task :normalize_loudness, [:target_files] do |t, args|
    require 'fileutils'
    require 'streamio-ffmpeg'

    target_lufs = -23
    true_peak = -5
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
      unless (filepath.match?(extensions)) && File.exist?(filepath)
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
