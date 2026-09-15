# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require 'factbase/inv'
require 'time'
require_relative '../test__helper'

class TestLatestAssessment < Minitest::Test
  def test_keeps_the_previous_fact_when_a_write_fails
    fb =
      Factbase::Inv.new(Factbase.new) do |prop, _value|
        raise('the storage refused this write') if prop == 'total'
      end
    old = fb.insert
    old.what = 'latest-assessment'
    old.when = Time.parse('2024-07-01T08:00:00Z')
    old.text = 'Stale assessment.'
    fresh = fb.insert
    fresh.what = 'assessment'
    fresh.when = Time.parse('2024-10-01T10:00:00Z')
    fresh.text = 'Fresh assessment.'
    assert_raises(StandardError) do
      load_it('latest-assessment', fb)
    end
    found = fb.query('(eq what "latest-assessment")').each.to_a
    assert_equal(1, found.size, 'the previous assessment must survive a failed replacement')
    assert_equal('Stale assessment.', found.first.text)
  end
end
