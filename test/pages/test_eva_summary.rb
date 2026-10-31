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

  def test_page_summarizes_the_latest_of_two_past_facts
    text = summary(
      '<f><what>earned-value</what><when>2026-09-20T00:00:00Z</when><ac>100</ac><ev>90</ev><pv>100</pv></f>' \
      '<f><what>earned-value</what><when>2026-10-20T00:00:00Z</when><ac>500</ac><ev>900</ev><pv>300</pv></f>'
    )
    assert_includes(text, 'AC: 500, EV: 900, PV: 300, CPI: 1.80, SPI: 3.00.', text)
    refute_includes(text, 'AC: 100', text)
  end

  def test_page_summarizes_the_latest_of_three_past_facts
    text = summary(
      '<f><what>earned-value</what><when>2026-08-20T00:00:00Z</when><ac>10</ac><ev>20</ev><pv>40</pv></f>' \
      '<f><what>earned-value</what><when>2026-09-20T00:00:00Z</when><ac>100</ac><ev>90</ev><pv>100</pv></f>' \
      '<f><what>earned-value</what><when>2026-10-20T00:00:00Z</when><ac>200</ac><ev>100</ev><pv>50</pv></f>'
    )
    assert_includes(text, 'AC: 200, EV: 100, PV: 50, CPI: 0.50, SPI: 2.00.', text)
  end

  def test_page_summarizes_a_single_fact
    text = summary(
      '<f><what>earned-value</what><when>2026-10-20T00:00:00Z</when><ac>100</ac><ev>90</ev><pv>100</pv></f>'
    )
    assert_includes(text, 'AC: 100, EV: 90, PV: 100, CPI: 0.90, SPI: 0.90.', text)
  end

  private

  def summary(facts)
    xslt(
      '<xsl:apply-imports/>',
      "<fb>#{facts}</fb>",
      'today' => '2026-10-29T00:00:00Z', 'css' => '', 'js' => '', 'name' => 'test', 'logo' => 'x',
      'url' => 'https://example.com', 'version' => '0.0.1', 'latest-version' => '0.0.1', 'fbe' => '0.0.50',
      'adless' => 'false', 'css-links' => '', 'js-links' => ''
    ).text.gsub(/\s+/, ' ')
  end
end
