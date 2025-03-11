# frozen_string_literal: true

require_relative "lib/road_to_rubykaigi/version"

Gem::Specification.new do |spec|
  spec.name = "road_to_rubykaigi"
  spec.version = RoadToRubykaigi::VERSION
  spec.authors = ["makicamel"]
  spec.email = ["unright@gmail.com"]

  spec.summary = "A retro ASCII action game where Rubyist overcomes a looming deadline and bugs on your way to RubyKaigi"
  spec.description = "Road to RubyKaigi is a Ruby gem that delivers a nostalgic, text-based action game experience. Dodge obstacles, overcome bugs, and beat the deadline to reach RubyKaigi. All in your terminal."
  spec.homepage = "https://github.com/makicamel/road_to_rubykaigi"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/makicamel/road_to_rubykaigi/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/console bin/setup test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = ["road_to_rubykaigi"]
  spec.require_paths = ["lib"]

  spec.add_dependency "fiddle"
end
