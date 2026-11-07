# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'tmpdir'
require_relative 'test__helper'

class TestCompiledHelper < Minitest::Test
  def test_honors_frozen_string_literal
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'judge.rb')
      File.write(file, "# frozen_string_literal: true\ns = 'judge'\ns << ' mutated'\n")
      assert_raises(FrozenError) { compiled(file).call }
    end
  end

  def test_runs_the_body_on_every_call
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'judge.rb')
      File.write(file, "$compiled_probe = ($compiled_probe || 0) + 1\n")
      body = compiled(file)
      2.times { body.call }
      assert_equal(2, $compiled_probe)
    end
  end
end
