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

  def test_keeps_counting_days_until_the_time_of_day_comes
    assert_equal('11 months ago', relative('2025-10-16T23:00:00Z', '2026-10-16T00:00:00Z'))
    assert_equal('one year ago', relative('2025-10-16T23:00:00Z', '2026-10-16T23:00:00Z'))
    assert_equal('30 days ago', relative('2026-01-15T23:00:00Z', '2026-02-15T00:00:00Z'))
    assert_equal('one month ago', relative('2026-01-15T23:00:00Z', '2026-02-15T23:00:00Z'))
  end

  def test_shows_a_future_moment_as_a_future_interval
    assert_equal('in 2 days', relative('2026-10-06T12:00:00Z', '2026-10-04T12:00:00Z'))
    assert_equal('in one hour', relative('2026-10-04T13:00:00Z', '2026-10-04T12:00:00Z'))
    assert_equal('in one month', relative('2026-03-01T00:00:00Z', '2026-02-01T00:00:00Z'))
  end

  def test_keeps_a_moment_less_than_a_minute_away_as_just_now
    assert_equal('just now', relative('2026-10-04T12:00:30Z', '2026-10-04T12:00:00Z'))
  end

  def test_counts_minutes_within_the_first_hour
    assert_equal('one minute ago', relative('2026-10-04T12:00:00Z', '2026-10-04T12:01:00Z'))
    assert_equal('5 minutes ago', relative('2026-10-04T12:00:00Z', '2026-10-04T12:05:00Z'))
    assert_equal('59 minutes ago', relative('2026-10-04T12:00:00Z', '2026-10-04T12:59:00Z'))
  end

  def test_shows_a_moment_minutes_ahead_in_minutes
    assert_equal('in 5 minutes', relative('2026-10-04T12:05:00Z', '2026-10-04T12:00:00Z'))
    assert_equal(
      'in 59 minutes', relative('2026-10-04T12:59:00Z', '2026-10-04T12:00:00Z'),
      'a moment just under an hour ahead must read in minutes'
    )
  end

  def test_shows_one_minute_ahead_as_a_single_minute
    assert_equal(
      'in one minute', relative('2026-10-04T12:01:00Z', '2026-10-04T12:00:00Z'),
      'a moment one minute ahead must not read as just now'
    )
  end

  def test_switches_from_minutes_to_hours_at_sixty_minutes
    assert_equal(
      'one hour ago', relative('2026-10-04T12:00:00Z', '2026-10-04T13:00:00Z'),
      'sixty minutes must read as one hour'
    )
    assert_equal(
      '59 minutes ago', relative('2026-10-04T12:00:00Z', '2026-10-04T12:59:59Z'),
      'a moment just under an hour must still read in minutes'
    )
  end

  def test_tells_the_age_of_an_outdated_page_in_relative_time
    script = [
      "let message = ''; global.$ = (s) => (s === 'footer' ? { prepend: (m) => { message = m; } } : " \
      '{ attr: () => new Date(Date.now() - (7 * 24 * 3600 * 1000)).toISOString(), length: 0 });',
      File.read(File.join(__dir__, '../../js/outdated.js')),
      'displayOutdatedWarning(); process.stdout.write(message);'
    ].join("\n")
    out, status = Open3.capture2({ 'TZ' => 'UTC' }, 'node', '-e', script)
    assert_predicate(status, :success?, out)
    assert_includes(out, 'This page was generated 7 days ago.', out)
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
