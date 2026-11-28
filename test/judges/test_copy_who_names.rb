# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require_relative '../test__helper'

class TestCopyWhoNames < Minitest::Test
  def test_copies_the_name_to_a_fact_of_the_same_person
    fb = Factbase.new
    n = fb.insert
    n.what = 'who-has-name'
    n.who = 42
    n.name = 'jeff'
    n.when = Time.parse('2024-07-01T00:00:00Z')
    f = fb.insert
    f.what = 'award'
    f.award = 1
    f.when = n.when
    f.why = 'for contributing'
    f.who = 42
    load_it('copy-who-names', fb)
    assert_equal(['jeff'], fb.query('(eq what "award")').each.first['who_name'], fb.to_json)
  end

  def test_ignores_empty_and_whitespace_only_names
    fb = Factbase.new
    valid = fb.insert
    valid.what = 'who-has-name'
    valid.who = 42
    valid.name = 'jeff'
    valid.when = Time.parse('2024-07-01T00:00:00Z')
    blank = fb.insert
    blank.what = 'who-has-name'
    blank.who = 42
    blank.name = '   '
    blank.when = Time.parse('2024-07-02T00:00:00Z')
    empty = fb.insert
    empty.what = 'who-has-name'
    empty.who = 99
    empty.name = "\t\n "
    empty.when = Time.parse('2024-07-02T00:00:00Z')
    first = fb.insert
    first.what = 'award'
    first.award = 1
    first.when = valid.when
    first.why = 'for contributing'
    first.who = 42
    second = fb.insert
    second.what = 'award'
    second.award = 2
    second.when = valid.when
    second.why = 'for contributing'
    second.who = 99
    load_it('copy-who-names', fb)
    assert_equal(['jeff'], first['who_name'], fb.to_json)
    assert_nil(second['who_name'], fb.to_json)
  end
end
