# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'tmpdir'
require_relative 'test__helper'

class TestCompiled < Minitest::Test
  def test_preserves_frozen_string_literals
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'judge.rb')
      File.write(file, "# frozen_string_literal: true\n'judge' << ' changed'\n")
      assert_raises(FrozenError) { compiled(file).call }
    end
  end

  def test_compiles_once_and_runs_the_body_on_every_call
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'judge.rb')
      File.write(file, "@calls = (@calls || 0) + 1\n")
      body = compiled(file)
      File.write(file, "raise 'reloaded'\n")
      assert_equal(1, body.call)
      assert_equal(2, body.call)
    end
  end

  def test_keeps_judge_methods_isolated
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'judge.rb')
      File.write(file, "def judge_value\n  42\nend\njudge_value\n")
      assert_equal(42, compiled(file).call)
      refute_respond_to(Object.new, :judge_value)
    end
  end
end
