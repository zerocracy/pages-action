# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'open3'
require_relative 'test__helper'

class TestEntryToday < Minitest::Test
  def test_rejects_an_impossible_date_time
    [
      '2026-02-30T12:00:00Z',
      '2025-02-29T12:00:00Z',
      '2026-04-31T12:00:00Z',
      '2026-00-10T12:00:00Z',
      '2026-13-10T12:00:00Z',
      '2026-09-00T12:00:00Z',
      '2026-09-31T12:00:00Z',
      '2026-09-29T24:00:00Z',
      '2026-09-29T25:00:00Z',
      '2026-09-29T12:60:00Z',
      '2026-09-29T12:00:60Z',
      '2026-09-29T12:00:00+15:00',
      '2026-09-29T12:00:00+14:01',
      '2026-09-29T12:00:00-14:01',
      '2026-09-29T12:00:00+05:60'
    ].each do |value|
      _, err, status = run_today(value)
      assert_equal(1, status.exitstatus, "#{value} was not rejected")
      assert_includes(err, 'today', "#{value} was rejected without naming today")
    end
  end

  def test_rejects_a_malformed_date_time
    _, err, status = run_today('2026-09-29T12:00')
    assert_equal(1, status.exitstatus, 'an incomplete date-time was not rejected')
    assert_includes(err, 'today', 'the format error does not name today')
  end

  def test_accepts_an_existing_date_time
    [
      '2024-02-29T12:00:00Z',
      '2026-09-29T12:00:00.123Z',
      '2026-09-29T12:00:00+14:00',
      '2026-09-29T12:00:00-14:00',
      '2026-09-29T12:00:00+05:30',
      '2026-09-29T12:00:00'
    ].each do |value|
      out, err, status = run_today(value)
      assert_predicate(status, :success?, err)
      assert_includes(out, "The 'today' is set to:", "#{value} was not reported as set")
    end
  end

  def test_appends_z_to_a_value_without_a_time_zone
    out, err, status = run_today('2026-09-29T12:00:00')
    assert_predicate(status, :success?, err)
    assert_includes(out, "The 'today' is set to: '2026-09-29T12:00:00Z'")
  end

  private

  def run_today(value)
    Open3.capture3({ 'INPUT_TODAY' => value }, 'bash', '-e', '-c', today_block)
  end

  def today_block
    source = File.read(File.join(__dir__, '..', 'entry.sh'))
    block = source[/^if \[ -z "\$\{INPUT_TODAY\}" \]; then\n(?:.*\n)*?^fi\n/]
    refute_nil(block, 'No today validation found in entry.sh')
    block
  end
end
