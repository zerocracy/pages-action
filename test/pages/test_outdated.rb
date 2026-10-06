# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'open3'
require_relative '../test__helper'

class TestOutdated < Minitest::Test
  def test_counts_a_month_that_ends_on_the_last_day_of_a_shorter_month
    {
      '2026-01-31T00:00:00Z' => '2026-02-28T00:00:00Z',
      '2026-03-31T00:00:00Z' => '2026-04-30T00:00:00Z'
    }.each do |start, finish|
      assert_equal('one month ago', relative(start, finish), "from #{start} to #{finish}")
    end
  end

  def test_keeps_counting_days_before_the_month_is_over
    assert_equal('27 days ago', relative('2026-01-31T00:00:00Z', '2026-02-27T00:00:00Z'))
  end

  private

  def relative(start, finish)
    script = [
      'global.$ = () => {};',
      File.read(File.join(__dir__, '../../js/outdated.js')),
      "const s = new Date('#{start}');",
      "process.stdout.write(formatRelativeTime(new Date('#{finish}') - s, s));"
    ].join("\n")
    out, status = Open3.capture2({ 'TZ' => 'UTC' }, 'node', '-e', script)
    assert_predicate(status, :success?, out)
    out
  end
end
