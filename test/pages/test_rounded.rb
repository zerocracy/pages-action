# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

class TestRounded < Minitest::Test
  def test_preserves_large_finite_values_when_scaling_overflows
    cases = %w[2e307 -2e307 1.7e308 -1.7e308].product([10, 100])
    values = cases.map { |value, factor| "<v factor='#{factor}'>#{value}</v>" }.join
    xml = xslt(
      '<r><xsl:for-each select="/values/v">
        <xsl:variable name="rounded" select="z:rounded(xs:double(.), xs:integer(@factor))"/>
        <v same="{$rounded = xs:double(.)}" finite="{$rounded = $rounded and abs($rounded) != xs:double(\'INF\')}">
          <xsl:value-of select="$rounded"/>
        </v>
      </xsl:for-each></r>',
      "<values>#{values}</values>"
    )
    assert_equal(Array.new(cases.size, 'true'), xml.xpath('/r/v/@same').map(&:text), xml)
    assert_equal(Array.new(cases.size, 'true'), xml.xpath('/r/v/@finite').map(&:text), xml)
  end

  def test_rounds_ordinary_halves_away_from_zero
    cases = [[1.25, 10, 1.3], [-1.25, 10, -1.3], [2.5, 1, 3], [-2.5, 1, -3], [0, 100, 0]]
    values = cases.map do |value, factor, expected|
      "<v factor='#{factor}' expected='#{expected}'>#{value}</v>"
    end.join
    xml = xslt(
      '<r><xsl:for-each select="/values/v">
        <xsl:variable name="rounded" select="z:rounded(xs:double(.), xs:integer(@factor))"/>
        <v same="{$rounded = xs:double(@expected)}"><xsl:value-of select="$rounded"/></v>
      </xsl:for-each></r>',
      "<values>#{values}</values>"
    )
    assert_equal(Array.new(cases.size, 'true'), xml.xpath('/r/v/@same').map(&:text), xml)
  end
end
