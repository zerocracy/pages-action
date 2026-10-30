# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'nokogiri'
require_relative '../test__helper'

class TestRounded < Minitest::Test
  def test_rounds_a_half_between_zero_and_one_up
    assert_equal('0.3', rounded('0.25', 10), 'a half below one was rounded down')
  end

  def test_rounds_close_to_one_up_to_one
    assert_equal('1', rounded('0.95', 10), 'a value close to one was not rounded to one')
  end

  def test_rounds_a_negative_half_away_from_zero
    assert_equal('-0.3', rounded('-0.25', 10), 'a negative half was not rounded away from zero')
  end

  def test_keeps_zero_as_zero
    assert_equal('0', rounded('0', 10), 'zero changed')
  end

  def test_rounds_a_half_below_one_to_hundredths
    assert_equal('0.13', rounded('0.125', 100), 'a half below one was rounded down to hundredths')
  end

  private

  def rounded(value, factor)
    xslt("<r><xsl:value-of select=\"z:rounded(#{value}, #{factor})\"/></r>", '<fb/>').xpath('/r').text
  end
end
