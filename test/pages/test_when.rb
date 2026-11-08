# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'nokogiri'
require_relative '../test__helper'

class TestWhen < Minitest::Test
  def test_prints_a_date_without_a_timezone
    xml = xslt(
      '<r><xsl:value-of select="z:day(xs:date(z:when(/fb/f/when)))"/></r>',
      '<fb><f><when>2026-07-20T00:00:00Z</when></f></fb>'
    )
    assert_equal('2026-07-20', xml.xpath('/r').text, xml)
  end

  def test_dates_the_assessment_without_a_timezone
    xml = xslt(
      "<xsl:apply-templates select='/' mode='assessment'/>",
      "<fb><f><what>latest-assessment</what><text>All good.</text>
      <when>2026-09-01T00:00:00Z</when><total>1</total></f></fb>"
    )
    pre = xml.xpath("//*[local-name()='pre']").text
    refute_includes(pre, '2026-09-01Z', pre)
    assert_includes(pre, '2026-09-01', pre)
  end

  def test_takes_the_earliest_of_two_values_given_in_reverse_order
    assert_equal(
      '2024-09-02',
      day_of('<v>2024-09-25T10:00:00Z</v><v>2024-09-02T10:00:00Z</v>'),
      'the latest of two values was taken'
    )
  end

  def test_takes_the_earliest_of_three_values_in_any_order
    assert_equal(
      '2024-08-30',
      day_of('<v>2024-09-25T10:00:00Z</v><v>2024-08-30T10:00:00Z</v><v>2024-09-02T10:00:00Z</v>'),
      'the earliest of three values was not taken'
    )
  end

  def test_compares_values_as_moments_not_as_text
    assert_equal(
      '2024-09-02',
      day_of('<v>2024-09-01T23:30:00Z</v><v>2024-09-02T01:00:00+03:00</v>'),
      'the values were compared as text'
    )
  end

  private

  def day_of(values)
    xslt(
      '<r><xsl:value-of select="z:day(xs:date(z:when(/fb/f/when)))"/></r>',
      "<fb><f><when>#{values}</when></f></fb>"
    ).xpath('/r').text
  end
end
