# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require 'time'
require_relative '../test__helper'

class TestNormalizeMetrics < Minitest::Test
  def test_recomputes_when_an_earlier_sample_arrives
    fb = Factbase.new
    later = fb.insert
    later._id = 1
    later.what = 'quality-of-service'
    later.when = Time.parse('2024-01-08T00:00:00Z')
    later.average_issue_lifetime = 200
    load_it('normalize-metrics', fb)
    earlier = fb.insert
    earlier._id = 2
    earlier.what = 'quality-of-service'
    earlier.when = Time.parse('2024-01-01T00:00:00Z')
    earlier.average_issue_lifetime = 100
    load_it('normalize-metrics', fb)
    f = fb.query('(eq average_issue_lifetime 200)').each.to_a.first
    assert_in_delta(1.0, f['n_average_issue_lifetime'].first, 0.0001, fb.to_json)
  end

  def test_removes_obsolete_values_when_the_earliest_metric_becomes_zero
    fb = Factbase.new
    [1, 2].each do |i|
      f = fb.insert
      f._id = i
      f.what = 'quantity-of-deliverables'
      f.when = Time.parse("2026-10-0#{i}T00:00:00Z")
      f.details = 'A valid measurement of the current project.'
      f.total_commits = i
    end
    load_it('normalize-metrics', fb)
    Fbe.overwrite(fb.query('(eq _id 1)').each.to_a.first, 'total_commits', 0, fb: fb)
    load_it('normalize-metrics', fb)
    fb.query('(always)').each do |f|
      assert_nil(f['n_total_commits'], fb.to_json)
    end
    assert_equal(2, fb.query('(always)').each.to_a.size, fb.to_json)
    assert_equal([2], fb.query('(eq total_commits 2)').each.to_a.first['_id'], fb.to_json)
  end
end
