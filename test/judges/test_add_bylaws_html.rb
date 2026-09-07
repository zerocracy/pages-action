# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require_relative '../test__helper'

class TestAddBylawsHtml < Minitest::Test
  def test_keeps_the_bylaws_when_there_is_nothing_to_build
    fb = Factbase.new
    pmp = fb.insert
    pmp.what = 'pmp'
    pmp.area = 'hr'
    pmp.hr_bonus = '(award (give 10 "for nothing"))'
    load_it('add-bylaws-html', fb)
    assert_equal(1, fb.query('(eq what "bylaws")').each.to_a.size, fb.to_json)
    fb.query('(and (eq what "pmp") (eq area "hr"))').delete!
    quiet = fb.insert
    quiet.what = 'pmp'
    quiet.area = 'hr'
    quiet.hr_balance = 42
    load_it('add-bylaws-html', fb)
    assert_equal(1, fb.query('(eq what "bylaws")').each.to_a.size, fb.to_json)
  end
end
