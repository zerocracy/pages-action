# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'coverage'
require 'tmpdir'
require_relative 'test__helper'

class TestCompiled < Minitest::Test
  def test_accumulates_coverage_across_runs
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'judge.rb')
      File.write(file, "return if $fb.empty?\n$fb << :visited\n")
      judge = compiled(file)
      $fb = []
      judge.call
      $fb = [:first]
      judge.call
      assert_equal(%i[first visited], $fb)
      $fb = []
      judge.call
      assert_equal([], $fb)
      assert_equal(1, Coverage.peek_result.fetch(file).fetch(:lines).fetch(1))
    end
  end

  def test_keeps_methods_private_to_each_judge
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'judge.rb')
      File.write(file, "def compiled_judge_value\n  :first\nend\n$fb << compiled_judge_value\n")
      first = compiled(file)
      File.write(file, "def compiled_judge_value\n  :second\nend\n$fb << compiled_judge_value\n")
      second = compiled(file)
      $fb = []
      first.call
      second.call
      first.call
      assert_equal(%i[first second first], $fb)
      refute_includes(Object.private_instance_methods, :compiled_judge_value)
    end
  end
end
