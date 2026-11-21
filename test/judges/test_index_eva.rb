# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
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

  def test_keeps_unit_indexes_for_equal_amounts_beyond_float_range
    fb = Factbase.new
    f = fb.insert
    f.what = 'earned-value'
    f.when = Time.parse('2024-07-01T00:00:00Z')
    f.ev = 10**400
    f.ac = 10**400
    f.pv = 10**400
    load_it('index-eva', fb)
    f = fb.query('(eq what "earned-value")').each.first
    assert_equal([1.0, 1.0], [f['n_cpi'].first, f['n_spi'].first])
  end

  def test_skips_non_finite_or_non_numeric_eva_values
    [
      { ev: Float::INFINITY, ac: 10.0, pv: 10.0 },
      { ev: -Float::INFINITY, ac: 10.0, pv: 10.0 },
      { ev: Float::NAN, ac: 10.0, pv: 10.0 },
      { ev: 10.0, ac: Float::INFINITY, pv: Float::NAN },
      { ev: 'abc', ac: 10.0, pv: 10.0 },
      { ev: 10.0, ac: 'abc', pv: 'abc' },
      { ev: 10**400, ac: 1, pv: 1 }
    ].each do |input|
      fb = Factbase.new
      f = fb.insert
      f.what = 'earned-value'
      f.when = Time.parse('2024-07-01T00:00:00Z')
      f.ev = input[:ev]
      f.ac = input[:ac]
      f.pv = input[:pv]
      load_it('index-eva', fb)
      fact = fb.query('(eq what "earned-value")').each.first
      assert_nil(fact['n_cpi'], "Expected n_cpi to be skipped for #{input.inspect}")
      assert_nil(fact['n_spi'], "Expected n_spi to be skipped for #{input.inspect}")
    end
  end
end
