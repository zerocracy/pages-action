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

  def test_ends_the_pre_right_after_the_date
    xml = xslt(
      "<div><xsl:apply-templates select='/' mode='assessment'/></div>",
      "<fb><f><what>latest-assessment</what><text>Line one.\nLine two.</text>
      <when>2026-09-01T00:00:00Z</when><total>1</total></f></fb>"
    )
    pre = xml.xpath("//*[local-name()='pre']").text
    assert_match(/2026-09-01\z/, pre)
  end
end
