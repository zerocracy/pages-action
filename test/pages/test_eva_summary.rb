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

  def test_rejects_nonfinite_values_in_each_amount_and_property_shape
    names = %w[ac ev pv]
    cases = %w[NaN INF -INF 1e309 -1e309].product(names, [false, true])
    facts = cases.map do |value, invalid, wrapped|
      amounts = names.map do |name|
        number = name == invalid ? value : '2'
        content = wrapped ? "<v>#{number}</v><v>2</v>" : number
        "<#{name}>#{content}</#{name}>"
      end.join
      "<f><what>earned-value</what>#{amounts}</f>"
    end.join
    xml = xslt('<r><xsl:apply-templates select="/fb/f"/></r>', "<fb>#{facts}</fb>")
    texts = xml.xpath('/r/p').map { |node| node.text.strip }
    assert_equal(cases.size, texts.size, xml)
    cases.zip(texts).each do |scenario, text|
      assert(text.start_with?('Not enough data'), "#{scenario.inspect}: #{text}")
    end
  end

  def test_keeps_zero_negative_and_large_finite_amounts
    facts = [[4, 0, 6], [4, -3, 6], %w[1e307 1e307 1e307]].map do |ac, ev, pv|
      "<f><what>earned-value</what><ac>#{ac}</ac><ev>#{ev}</ev><pv>#{pv}</pv></f>"
    end.join
    xml = xslt('<r><xsl:apply-templates select="/fb/f"/></r>', "<fb>#{facts}</fb>")
    texts = xml.xpath('/r/p').map { |node| node.text.strip }
    assert_equal('AC: 4, EV: 0, PV: 6, CPI: 0.00, SPI: 0.00.', texts[0], xml)
    assert_equal('AC: 4, EV: -3, PV: 6, CPI: -0.75, SPI: -0.50.', texts[1], xml)
    assert_includes(texts[2], 'CPI: 1.00, SPI: 1.00.', xml)
  end
end
