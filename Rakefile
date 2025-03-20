# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
import "util/audio.rake"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard]
