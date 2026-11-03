# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require 'fbe/overwrite'
require_relative '../test__helper'

class TestIndexEva < Minitest::Test
  def test_adds_both_indexes
    fb = Factbase.new
    f = fb.insert
    f.what = 'earned-value'
    f.when = Time.parse('2024-07-01T00:00:00Z')
    f.ev = 50
    f.ac = 100
    f.pv = 25
    load_it('index-eva', fb)
    f = fb.query('(eq what "earned-value")').each.first
    assert_in_delta(0.5, f['n_cpi'].first, 0.001, fb.to_json)
    assert_in_delta(2.0, f['n_spi'].first, 0.001, fb.to_json)
  end

  def test_updates_both_indexes_after_a_correction
    fb = Factbase.new
    f = fb.insert
    f._id = 1
    f.what = 'earned-value'
    f.when = Time.parse('2024-07-01T00:00:00Z')
    f.ev = 40
    f.ac = 80
    f.pv = 100
    load_it('index-eva', fb)
    Fbe.overwrite(fb.query('(eq _id 1)').each.first, 'ev', 80, fb: fb)
    load_it('index-eva', fb)
    facts = fb.query('(eq what "earned-value")').each.to_a
    assert_equal(1, facts.size, fb.to_json)
    assert_in_delta(1.0, facts.first['n_cpi'].first, 0.001, fb.to_json)
    assert_in_delta(0.8, facts.first['n_spi'].first, 0.001, fb.to_json)
  end
end
