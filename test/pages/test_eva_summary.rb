# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

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

  def test_template_uses_one_value_from_multi_valued_properties
    xml = xslt(
      '<r><xsl:apply-templates select="/fb/f"/></r>',
      '
      <fb>
        <f>
          <what>earned-value</what>
          <ac><v>4</v><v>5</v></ac>
          <ev>3</ev>
          <pv>6</pv>
        </f>
      </fb>
      '
    )
    assert_equal('AC: 4, EV: 3, PV: 6, CPI: 0.75, SPI: 0.50.', xml.xpath('/r').text.strip, xml)
  end

  def test_picks_the_latest_fact
    xml = xslt(
      "<r><xsl:value-of select=\"z:latest(/fb/f[what='earned-value'])/ev\"/></r>",
      '
      <fb>
        <f>
          <_id>10</_id>
          <what>earned-value</what>
          <when>2024-07-04T10:00:00Z</when>
          <ev>90</ev>
        </f>
        <f>
          <_id>9</_id>
          <what>earned-value</what>
          <when>2024-06-01T10:00:00Z</when>
          <ev>10</ev>
        </f>
      </fb>
      ',
      'today' => '2024-07-05T00:00:00Z'
    )
    assert_equal('90', xml.xpath('/r/text()').to_s, xml)
  end
end
