# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'rubygems'

ENV['RACK_RUN'] = 'true'

task default: %i[test judges rubocop]

CLEAN.include('target')

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.warning = true
  test.verbose = false
end

desc 'Run all judges'
task :judges do
  live = ARGV.include?('--live') ? '' : '--disable live'
  sh "judges --verbose test #{live} --no-log judges"
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end
