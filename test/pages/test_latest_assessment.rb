# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require 'factbase/rules'
require_relative '../test__helper'

class TestLatestAssessment < Minitest::Test
  def test_preserves_factbase_when_replacement_is_rejected
    fb = assessment_factbase
    before = fb.export
    guarded = Factbase::Rules.new(fb, '(not (eq text "Fresh assessment"))')
    error = assert_raises(ArgumentError) { load_it('latest-assessment', guarded) }
    assert_includes(error.message, "doesn't match")
    assert_equal(before, fb.export)
  end

  def test_replaces_previous_summary
    fb = assessment_factbase
    load_it('latest-assessment', fb)
    latest = fb.query('(eq what "latest-assessment")').each.to_a
    assert_equal(1, latest.size)
    assert_equal('Fresh assessment', latest.first.text)
    assert_equal(Time.utc(2024, 7, 2), latest.first.when)
    assert_equal(1, latest.first.total)
  end

  def test_uses_earliest_value_when_comparing_multi_valued_dates
    fb = Factbase.new
    first = fb.insert
    first._id = 1
    first.what = 'assessment'
    first.text = 'Earlier effective date'
    first.when = Time.utc(2025, 1, 1)
    first.when = Time.utc(2024, 1, 1)
    second = fb.insert
    second._id = 2
    second.what = 'assessment'
    second.text = 'Latest effective date'
    second.when = Time.utc(2024, 6, 1)

    load_it('latest-assessment', fb)

    latest = fb.query('(eq what "latest-assessment")').each.to_a.fetch(0)
    assert_equal('Latest effective date', latest.text)
    assert_equal(Time.utc(2024, 6, 1), latest.when)
  end

  def test_keeps_factbase_without_source_assessments
    fb = assessment_factbase
    fb.query('(eq what "assessment")').delete!
    before = fb.export
    load_it('latest-assessment', fb)
    assert_equal(before, fb.export)
  end

  private

  def assessment_factbase
    fb = Factbase.new
    prior = fb.insert
    prior.what = 'latest-assessment'
    prior.text = 'Previous assessment'
    prior.when = Time.utc(2024, 7, 1)
    prior.total = 1
    source = fb.insert
    source.what = 'assessment'
    source.text = 'Fresh assessment'
    source.when = Time.utc(2024, 7, 2)
    fb
  end
end
