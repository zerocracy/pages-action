# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require_relative '../test__helper'

class TestAddBylawsHtml < Minitest::Test
  def test_keeps_the_bylaws_when_there_is_nothing_to_build
    fb = Factbase.new
    with_formula(fb)
    load_it('add-bylaws-html', fb)
    assert_equal(1, bylaws(fb), fb.to_json)
    without_formula(fb)
    load_it('add-bylaws-html', fb)
    assert_equal(1, bylaws(fb), fb.to_json)
    with_formula(fb)
    load_it('add-bylaws-html', fb)
    assert_equal(1, bylaws(fb), fb.to_json)
  end

  def test_keeps_underscores_inside_a_word_of_a_bylaw
    {
      'Penalty for max_hoc_value' => 'max_hoc_value',
      'Penalty for _large_ pulls' => '<em>large</em>'
    }.each do |explain, html|
      fb = Factbase.new
      f = fb.insert
      f.what = 'pmp'
      f.area = 'hr'
      f.hr_penalty = "(award (explain \"#{explain}\") (give 4 \"x\"))"
      load_it('add-bylaws-html', fb)
      assert_includes(fb.query('(eq what "bylaws")').each.to_a.first.html, html, fb.to_json)
    end
  end

  def test_skips_a_formula_that_cannot_be_rendered
    fb = Factbase.new
    with_formula(fb)
    fb.query('(eq what "pmp")').each.first.hr_newer = '(award (frobnicate 5) (give 7 "for something new"))'
    load_it('add-bylaws-html', fb)
    html = fb.query('(eq what "bylaws")').each.to_a.first.html
    assert_includes(html, '<strong>10</strong>', html)
    refute_includes(html, '<strong>7</strong>', html)
  end

  private

  def bylaws(fb)
    fb.query('(eq what "bylaws")').each.to_a.size
  end

  def with_formula(fb)
    fb.query('(and (eq what "pmp") (eq area "hr"))').delete!
    f = fb.insert
    f.what = 'pmp'
    f.area = 'hr'
    f.hr_bonus = '(award (give 10 "for nothing"))'
  end

  def without_formula(fb)
    fb.query('(and (eq what "pmp") (eq area "hr"))').delete!
    f = fb.insert
    f.what = 'pmp'
    f.area = 'hr'
    f.hr_balance = 42
  end
end
