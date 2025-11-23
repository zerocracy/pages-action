# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'online'
require 'nokogiri'
require 'w3c_validators'
require 'webmock/minitest'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestVitals < Minitest::Test
  def test_validate_html
    WebMock.enable_net_connect!
    html = File.join(__dir__, '../../target/html/simple-vitals.html')
    skip unless File.exist?(html)
    doc = File.read(html)
    xml =
      begin
        Nokogiri::XML.parse(doc) do |c|
          c.norecover
          c.strict
        end
      rescue StandardError => e
        raise "#{doc}\n\n#{e}"
      end
    assert_empty(xml.errors, xml)
    refute_empty(xml.xpath('/html'), xml)
    return unless online?
    WebMock.enable_net_connect!
    begin
      v = W3CValidators::NuValidator.new.validate_file(html)
      assert_empty(v.errors, "#{doc}\n\n#{v.errors.join('; ')}")
    rescue Errno::ECONNRESET, W3CValidators::ValidatorUnavailable, W3CValidators::ParsingError, OpenSSL::SSL::SSLError
      skip
    end
  end

  def test_fn_index
    {
      3.3 => ['darkgreen', '+3.30'],
      0 => ['darkgreen', '+0.00'],
      -1 => ['darkred', '-1.00']
    }.each do |k, v|
      xml = xslt(
        "<xsl:copy-of select='z:index(#{k})'/>",
        '<fb/>'
      )
      assert_equal(v[0], xml.xpath('/span/@class').to_s, xml)
      assert_equal(v[1], xml.xpath('/span/text()').to_s, xml)
    end
  end

  def test_fn_pmp
    xml = xslt(
      '<r><xsl:value-of select="z:pmp(\'hr\', \'foo\', \'bar\')"/></r>',
      '
      <fb>
        <f>
          <what>pmp</what>
          <area>foo</area>
          <xyz>test</xyz>
        </f>
      </fb>
      '
    )
    assert_equal('bar', xml.xpath('/r/text()').to_s, xml)
  end

  def test_fn_format_signed
    {
      3.3 => ['0.00', '+3.30'],
      0 => ['0.00', '+0.00'],
      -1 => ['0.00', '-1.00'],
      5.123 => ['0.0', '+5.1'],
      -2.456 => ['0.0', '-2.5'],
      0.0 => ['0.0', '+0.0'],
      10.5 => ['0', '+11'],
      -7.8 => ['0', '-8']
    }.each do |value, (format, expected)|
      xml = xslt(
        "<r><xsl:value-of select=\"z:format-signed(#{value}, '#{format}')\"/></r>",
        '<fb/>'
      )
      assert_equal(expected, xml.xpath('/r/text()').to_s, "Failed for value #{value} with format #{format}: #{xml}")
    end
  end

  def test_description_with_facts
    html = File.join(__dir__, '../../target/html/simple-vitals.html')
    skip unless File.exist?(html)
    doc = File.read(html)
    xml = Nokogiri::XML.parse(doc)
    desc = xml.xpath('//header/p[2]/text()').to_s
    assert_match(/simple/, desc, xml)
    assert_match(/average points per task/, desc, xml)
    assert_match(/total points earned/, desc, xml)
    assert_match(/contributors/, desc, xml)
  end

  def test_description_format
    html = File.join(__dir__, '../../target/html/simple-vitals.html')
    skip unless File.exist?(html)
    doc = File.read(html)
    xml = Nokogiri::XML.parse(doc)
    desc = xml.xpath('//header/p[2]/text()').to_s
    assert_match(/The "/, desc, xml)
    assert_match(/" product is supervised by Zerocracy/, desc, xml)
    assert_match(/average points per task,/, desc, xml)
    assert_match(/total points earned,/, desc, xml)
    assert_match(/contributors\./, desc, xml)
  end

  def test_description_contains_values
    html = File.join(__dir__, '../../target/html/simple-vitals.html')
    skip unless File.exist?(html)
    doc = File.read(html)
    xml = Nokogiri::XML.parse(doc)
    desc = xml.xpath('//header/p[2]/text()').to_s
    refute_empty(desc, xml)
    assert_match(/average points per task/, desc, xml)
    assert_match(/total points earned/, desc, xml)
    assert_match(/contributors/, desc, xml)
  end

  def test_description_values
    html = File.join(__dir__, '../../target/html/simple-vitals.html')
    skip unless File.exist?(html)
    doc = File.read(html)
    xml = Nokogiri::XML.parse(doc)
    desc = xml.xpath('//header/p[2]/text()').to_s
    # Based on simple.yml test data:
    # Awards: 14, -56, -8, 15, -24, 55
    # Sum: -4, Count: 6, Average: -4/6 = -0.666... ≈ -0.7
    # Contributors: 2 (6305016 and 526301)
    assert_match(/"simple"/, desc, xml)
    assert_match(/-0\.7 average points per task/, desc, xml)
    assert_match(/-4 total points earned/, desc, xml)
    assert_match(/2 contributors/, desc, xml)
  end
end
