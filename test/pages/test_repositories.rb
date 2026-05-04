# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestRepositories < Minitest::Test
  def test_emits_relative_time_for_repository_updated_at
    xml = xslt(
      '<xsl:apply-templates mode="repositories" select="/"/>',
      '
      <fb>
        <f>
          <what>repo-details</what>
          <repository_name>foo/bar</repository_name>
          <description>desc</description>
          <stars>1</stars>
          <forks>2</forks>
          <language>Ruby</language>
          <open_issues>3</open_issues>
          <updated_at>2024-07-05T00:00:00Z</updated_at>
        </f>
      </fb>
      '
    )
    times = xml.xpath('//*[local-name()="time" and @class="relative-time"]')
    refute_empty(
      times,
      "Expected a <time class=\"relative-time\"> element so js/outdated.js can " \
      "convert the repository updated_at date to relative time, got: #{xml}"
    )
    assert(
      times.any? { |t| t['datetime']&.start_with?('2024-07-05') },
      "Expected the relative-time element to carry the updated_at date in its " \
      "datetime attribute, got: #{times.map { |t| t['datetime'] }.inspect}"
    )
  end
end
