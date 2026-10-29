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

  def test_renders_a_formula_of_a_later_pmp_fact
    fb = Factbase.new
    first = fb.insert
    first.what = 'pmp'
    first.area = 'hr'
    first.days_of_running_balance = 56
    second = fb.insert
    second.what = 'pmp'
    second.area = 'hr'
    second.hr_bonus = '(award (give 10 "for nothing"))'
    load_it('add-bylaws-html', fb)
    assert_equal(1, bylaws(fb), fb.to_json)
    assert_includes(html(fb), '<strong>10</strong>', fb.to_json)
  end

  def test_renders_formulas_of_every_pmp_fact
    fb = Factbase.new
    first = fb.insert
    first.what = 'pmp'
    first.area = 'hr'
    first.first_bonus = '(award (give 10 "for the first thing"))'
    second = fb.insert
    second.what = 'pmp'
    second.area = 'hr'
    second.second_bonus = '(award (give 20 "for the second thing"))'
    load_it('add-bylaws-html', fb)
    assert_includes(html(fb), '<strong>10</strong>', fb.to_json)
    assert_includes(html(fb), '<strong>20</strong>', fb.to_json)
  end

  def test_renders_the_same_property_from_the_first_fact_only
    fb = Factbase.new
    first = fb.insert
    first.what = 'pmp'
    first.area = 'hr'
    first.hr_bonus = '(award (give 10 "for the first thing"))'
    second = fb.insert
    second.what = 'pmp'
    second.area = 'hr'
    second.hr_bonus = '(award (give 20 "for the second thing"))'
    load_it('add-bylaws-html', fb)
    assert_includes(html(fb), '<strong>10</strong>', fb.to_json)
    refute_includes(html(fb), '<strong>20</strong>', fb.to_json)
  end

  private

  def html(fb)
    fb.query('(eq what "bylaws")').each.to_a.first.html.to_s
  end

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
