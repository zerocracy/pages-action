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
end
