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

  def test_keeps_zero_for_equal_values_beyond_float_range
    fb = Factbase.new
    2.times do |day|
      f = fb.insert
      f.what = 'quantity-of-deliverables'
      f.when = Time.parse("2024-01-0#{day + 1}T00:00:00Z")
      f.total_issues = 10**400
    end
    load_it('normalize-metrics', fb)
    assert_equal([0.0, 0.0], fb.query('(always)').each.map { |f| f['n_total_issues'].first })
  end

  def test_keeps_zero_for_equal_raw_samples_beyond_float_range
    fb = Factbase.new
    2.times do |day|
      f = fb.insert
      f.what = 'quality-of-service'
      f.when = Time.parse("2024-01-0#{day + 1}T00:00:00Z")
      f.some_issue_lifetime = 10**400
    end
    load_it('normalize-metrics', fb)
    assert_equal([0.0, 0.0], fb.query('(always)').each.map { |f| f['n_some_issue_lifetime'].first })
  end

  def test_removes_raw_sample_series_when_average_becomes_available
    fb = Factbase.new
    [10, 20].each_with_index do |val, idx|
      fact = fb.insert
      fact._id = idx + 1
      fact.what = 'quality-of-service'
      fact.when = Time.utc(2024, 1, idx + 1)
      fact.some_issue_lifetime = val
    end
    load_it('normalize-metrics', fb)
    fb.query('(always)').each do |fact|
      fact.average_issue_lifetime = fact.some_issue_lifetime
    end
    load_it('normalize-metrics', fb)
    fb.query('(always)').each do |fact|
      assert_nil(fact['n_some_issue_lifetime'])
      refute_nil(fact['n_average_issue_lifetime'])
    end
  end

  def test_normalizes_composite_metric
    fb = Factbase.new
    first = fb.insert
    first._id = 1
    first.what = 'quantity-of-deliverables'
    first.when = Time.utc(2024, 1, 1)
    first.composite = 50
    second = fb.insert
    second._id = 2
    second.what = 'quantity-of-deliverables'
    second.when = Time.utc(2024, 1, 2)
    second.composite = 100
    load_it('normalize-metrics', fb)
    target = fb.query('(eq _id 2)').each.to_a.first
    assert_in_delta(1.0, target['n_composite'].first, 0.0001)
  end

  def test_ignores_already_normalized_metric_names
    fb = Factbase.new
    first = fb.insert
    first._id = 1
    first.what = 'quality-of-service'
    first.when = Time.utc(2024, 1, 1)
    first.n_custom_metric = 42.0
    load_it('normalize-metrics', fb)
    target = fb.query('(eq _id 1)').each.to_a.first
    assert_nil(target['n_n_custom_metric'])
  end

  def test_skips_metric_when_baseline_is_zero
    fb = Factbase.new
    first = fb.insert
    first._id = 1
    first.what = 'quality-of-service'
    first.when = Time.utc(2024, 1, 1)
    first.average_latency = 0
    second = fb.insert
    second._id = 2
    second.what = 'quality-of-service'
    second.when = Time.utc(2024, 1, 2)
    second.average_latency = 10
    load_it('normalize-metrics', fb)
    target = fb.query('(eq _id 2)').each.to_a.first
    assert_nil(target['n_average_latency'])
  end

  def test_picks_baseline_from_subsequent_fact_when_earlier_fact_lacks_it
    fb = Factbase.new
    first = fb.insert
    first._id = 1
    first.what = 'quantity-of-deliverables'
    first.when = Time.utc(2024, 1, 1)
    first.total_builds = 10
    second = fb.insert
    second._id = 2
    second.what = 'quantity-of-deliverables'
    second.when = Time.utc(2024, 1, 2)
    second.total_builds = 20
    second.total_releases = 5
    third = fb.insert
    third._id = 3
    third.what = 'quantity-of-deliverables'
    third.when = Time.utc(2024, 1, 3)
    third.total_releases = 15
    load_it('normalize-metrics', fb)
    target = fb.query('(eq _id 3)').each.to_a.first
    assert_in_delta(2.0, target['n_total_releases'].first, 0.0001)
  end

  def test_handles_empty_facts_without_error
    fb = Factbase.new
    load_it('normalize-metrics', fb)
    assert_equal(0, fb.size)
  end

  def test_ignores_properties_without_underscore
    fb = Factbase.new
    f = fb.insert
    f._id = 1
    f.what = 'quality-of-service'
    f.when = Time.utc(2024, 1, 1)
    f.singleword = 42
    load_it('normalize-metrics', fb)
    assert_nil(fb.query('(eq _id 1)').each.to_a.first['n_singleword'])
  end

  def test_skips_fact_without_matching_properties
    fb = Factbase.new
    f = fb.insert
    f._id = 1
    f.what = 'quality-of-service'
    f.when = Time.utc(2024, 1, 1)
    load_it('normalize-metrics', fb)
    assert_equal(1, fb.size)
  end
end
