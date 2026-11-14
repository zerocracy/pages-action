# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require 'time'
require_relative '../test__helper'

class TestLatestAssessment < Minitest::Test
  def test_refreshes_the_summary_using_only_assessments_available_today
    fb = Factbase.new
    stale = fb.insert
    stale.what = 'latest-assessment'
    stale.text = 'Stale summary'
    %w[2024-07-01 2024-07-05 2024-07-06].each do |day|
      assessment = fb.insert
      assessment.what = 'assessment'
      assessment.when = Time.parse("#{day}T00:00:00Z")
      assessment.text = "Assessment on #{day}"
    end
    incomplete = fb.insert
    incomplete.what = 'assessment'
    incomplete.when = Time.parse('2024-07-04T00:00:00Z')
    load_it('latest-assessment', fb, 'today' => '2024-07-05T00:00:00Z')
    summaries = fb.query('(eq what "latest-assessment")').each.to_a
    assert_equal(1, summaries.size, fb.to_json)
    assert_equal('Assessment on 2024-07-05', summaries.first.text, fb.to_json)
    assert_equal(Time.parse('2024-07-05T00:00:00Z'), summaries.first.when, fb.to_json)
    assert_equal(2, summaries.first.total, fb.to_json)
  end

  def test_removes_a_stale_summary_when_no_assessments_remain
    fb = Factbase.new
    stale = fb.insert
    stale.what = 'latest-assessment'
    stale.text = 'Stale summary'
    load_it('latest-assessment', fb)
    assert_empty(fb.query('(eq what "latest-assessment")').each.to_a, fb.to_json)
  end
end
