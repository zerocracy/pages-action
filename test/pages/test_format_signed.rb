# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'nokogiri'
require_relative '../test__helper'

class TestFormatSigned < Minitest::Test
  def test_rounds_to_tenths
    assert_equal('+0.1', signed('0.14', '0.0'), 'the value was not rounded to tenths')
  end

  def test_rounds_to_hundredths
    assert_equal('+0.01', signed('0.0149', '0.00'), 'the value was not rounded to hundredths')
  end

  def test_rounds_negative_value_to_tenths
    assert_equal('-0.1', signed('-0.14', '0.0'), 'the negative value was not rounded to tenths')
  end

  def test_rounds_a_half_up_to_tenths
    assert_equal('+2.4', signed('2.36', '0.0'), 'the value was not rounded up to tenths')
  end

  def test_refuses_unknown_format
    assert_raises(StandardError, 'a format other than 0.0 or 0.00 was accepted') { signed('0.14', '0.000') }
  end

  private

  def signed(value, format)
    xslt("<r><xsl:value-of select=\"z:format-signed(#{value}, '#{format}')\"/></r>", '<fb/>').xpath('/r').text
  end
end
