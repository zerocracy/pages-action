# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'nokogiri'
require_relative '../test__helper'

class TestAssessment < Minitest::Test
  def test_breaks_the_line_before_the_date
    xml = xslt(
      "<xsl:apply-templates select='/' mode='assessment'/>",
      "<fb><f><what>latest-assessment</what><text>The project is healthy.</text>
      <when>2026-09-01T00:00:00Z</when><total>1</total></f></fb>"
    )
    pre = xml.xpath("//*[local-name()='pre']").text
    refute_includes(pre, 'healthy.Last assessed', pre)
    assert_includes(pre, "healthy.\nLast assessed ", pre)
  end

  def test_reads_well_once_the_date_becomes_relative
    xml = xslt(
      "<xsl:apply-templates select='/' mode='assessment'/>",
      "<fb><f><what>latest-assessment</what><text>The project is healthy.</text>
      <when>2026-09-01T00:00:00Z</when><total>1</total></f></fb>"
    )
    pre = xml.xpath("//*[local-name()='pre']").text
    refute_includes(pre, 'assessed on', pre)
  end

  def test_builds_the_datetime_from_one_moment
    xml = xslt(
      "<xsl:apply-templates select='/' mode='assessment'/>",
      "<fb><f><what>latest-assessment</what><text>All good.</text>
      <when><v>2024-07-01T00:00:00Z</v><v>2024-07-02T00:00:00Z</v></when><total>1</total></f></fb>"
    )
    assert_equal('2024-07-01T00:00:00Z', xml.xpath("//*[local-name()='time']/@datetime").to_s, xml)
  end

  def test_shows_no_warning_for_one_assessment
    xml = assessment_with(1)
    assert_empty(xml.xpath("//*[local-name()='p'][@class='darkred']"), 'one assessment was reported as many')
  end

  def test_warns_about_two_assessments
    xml = assessment_with(2)
    assert_equal(
      '2 assessments on factbase were found',
      xml.xpath("//*[local-name()='p'][@class='darkred']").text, 'two assessments were not reported'
    )
  end

  def test_warns_about_many_assessments
    xml = assessment_with(7)
    assert_equal(
      '7 assessments on factbase were found',
      xml.xpath("//*[local-name()='p'][@class='darkred']").text, 'many assessments were not reported'
    )
  end

  private

  def assessment_with(total)
    xslt(
      "<xsl:apply-templates select='/' mode='assessment'/>",
      "<fb><f><what>latest-assessment</what><text>All good.</text>
      <when>2024-09-15T00:00:00Z</when><total>#{total}</total></f></fb>"
    )
  end
end
