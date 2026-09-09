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
    refute_includes(pre, 'healthy.Last assessed on', pre)
    assert_includes(pre, "healthy.\nLast assessed on", pre)
  end
end
