# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'rake'
require_relative 'test__helper'

class TestRakefile < Minitest::Test
  def test_disables_live_judges_when_live_is_not_set
    assert_includes(judges(nil), '--disable live')
  end

  def test_disables_live_judges_when_live_is_false
    assert_includes(judges('false'), '--disable live')
  end

  def test_runs_live_judges_when_live_is_true
    refute_includes(judges('true'), '--disable live')
  end

  private

  def judges(live)
    before = [Rake.application, ENV.fetch('LIVE', nil), ENV.fetch('RACK_RUN', nil)]
    Rake.application = Rake::Application.new
    ENV['LIVE'] = live
    load(File.join(__dir__, '../Rakefile'))
    commands = []
    TOPLEVEL_BINDING.receiver.define_singleton_method(:sh) { |cmd| commands << cmd }
    Rake::Task['judges'].invoke
    commands.join(' ')
  ensure
    TOPLEVEL_BINDING.receiver.singleton_class.send(:remove_method, :sh)
    Rake.application = before[0]
    ENV['LIVE'] = before[1]
    ENV['RACK_RUN'] = before[2]
  end
end
