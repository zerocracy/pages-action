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

  def test_removes_normalized_samples_when_averages_arrive
    values = [10, 20]
    %w[quantity-of-deliverables quality-of-service].each do |what|
      fb = Factbase.new
      facts =
        values.each_with_index.map do |value, day|
          fact = fb.insert
          fact._id = day + 1
          fact.what = what
          fact.when = Time.utc(2026, 10, day + 1)
          fact.some_issue_lifetime = value
          fact.some_review_lifetime = value
          fact
        end
      load_it('normalize-metrics', fb)
      assert_equal([[0.0], [1.0]], facts.map { |f| f['n_some_issue_lifetime'] })
      facts.each { |f| f.average_issue_lifetime = f.some_issue_lifetime }
      load_it('normalize-metrics', fb)
      facts = fb.query('(always)').each.sort_by(&:_id)
      facts.each { |f| assert_nil(f['n_some_issue_lifetime'], fb.to_json) }
      assert_equal([[0.0], [1.0]], facts.map { |f| f['n_average_issue_lifetime'] })
      assert_equal([[0.0], [1.0]], facts.map { |f| f['n_some_review_lifetime'] })
      assert_equal([[10], [20]], facts.map { |f| f['some_issue_lifetime'] })
      load_it('normalize-metrics', fb)
      facts = fb.query('(always)').each.sort_by(&:_id)
      facts.each { |f| assert_nil(f['n_some_issue_lifetime'], fb.to_json) }
    end
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
end
