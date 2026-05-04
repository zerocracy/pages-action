# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestAssessment < Minitest::Test
  def test_emits_relative_time_for_assessment_date
    xml = xslt(
      '<xsl:apply-templates select="/fb/f"/>',
      '
      <fb>
        <f>
          <what>latest-assessment</what>
          <text>The factbase is fine.</text>
          <when>2024-07-05T00:00:00Z</when>
          <total>1</total>
        </f>
      </fb>
      '
    )
    times = xml.xpath('//*[local-name()="time" and @class="relative-time"]')
    refute_empty(
      times,
      "Expected a <time class=\"relative-time\"> element so js/outdated.js can " \
      "convert the assessment date to a human-readable relative time, but " \
      "got: #{xml}"
    )
    assert(
      times.any? { |t| t['datetime']&.start_with?('2024-07-05') },
      "Expected the relative-time element to carry the assessment date in its " \
      "datetime attribute, got: #{times.map { |t| t['datetime'] }.inspect}"
    )
  end
end
