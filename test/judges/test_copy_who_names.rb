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
    f.who = 42
    load_it('copy-who-names', fb)
    assert_equal(['jeff'], fb.query('(eq what "award")').each.first['who_name'], fb.to_json)
  end
end
