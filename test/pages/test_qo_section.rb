# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestQoSection < Minitest::Test
  def test_snake_case_to_title
    xml = xslt(
      '<r><xsl:value-of select="z:snake-case-to-title(\'average_issue_lifetime\')"/></r>',
      '
      <fb>
        <f>
          <when>2024-08-03T22:22:22.8492Z</when>
          <what>quality-of-service</what>
        </f>
      </fb>
      ',
      'today' => '2024-09-26T04:04:04Z'
    )
    assert_equal('Average Issue Lifetime', xml.xpath('//r/text()').to_s.strip)
  end
end
