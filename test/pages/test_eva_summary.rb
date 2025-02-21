# frozen_string_literal: true

# MIT License
#
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestEvaSummary < Minitest::Test
  def test_template_long
    xml = xslt(
      '<xsl:apply-templates select="/fb/f"/>',
      '
      <fb>
        <f>
          <what>earned-value</what>
          <ac>444</ac>
          <ev>555</ev>
          <pv>666</pv>
        </f>
      </fb>
      '
    )
    refute(xml.xpath('/p/text()').to_s.start_with?('Not enough data'))
  end

  def test_template_short
    xml = xslt(
      '<xsl:apply-templates select="/fb/f"/>',
      '
      <fb>
        <f>
          <what>earned-value</what>
        </f>
      </fb>
      '
    )
    assert(xml.xpath('/p/text()').to_s.start_with?('Not enough data'))
  end
end
