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
