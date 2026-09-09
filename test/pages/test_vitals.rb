# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'online'
require 'w3c_validators'
require 'webmock/minitest'
require_relative '../test__helper'

class TestVitals < Minitest::Test
  def test_validate_html_via_w3c
    WebMock.enable_net_connect!
    skip('not online') unless online?
    html = generate_vitals_html
    begin
      v = W3CValidators::NuValidator.new.validate_text(html)
      errors = v.errors.map { |e| "  Line #{e.line}: #{e.message.strip}" }.join("\n")
      assert_empty(v.errors, "W3C validation errors:\n#{errors}\n\nHTML:\n#{html}")
    rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT,
           SocketError, Net::OpenTimeout, Net::ReadTimeout,
           W3CValidators::ValidatorUnavailable, W3CValidators::ParsingError,
           OpenSSL::SSL::SSLError
      skip('W3C validator unavailable')
    end
  end

  def test_fn_index
    {
      3.3 => ['darkgreen', '3.30'],
      1 => ['darkgreen', '1.00'],
      0.2 => ['darkred', '0.20'],
      0 => ['darkred', '0.00']
    }.each do |k, v|
      xml = xslt("<xsl:copy-of select='z:index(#{k})'/>", '<fb/>')
      assert_equal(v[0], xml.xpath('/span/@class').to_s, xml)
      assert_equal(v[1], xml.xpath('/span/text()').to_s, xml)
    end
  end

  def test_renders_a_fact_that_has_two_moments
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      '
      <fb>
        <f>
          <what>pmp</what>
          <area>hr</area>
          <days_of_running_balance>7</days_of_running_balance>
        </f>
        <f>
          <what>something</what>
          <who>5</who>
        </f>
        <f>
          <is_human>1</is_human>
          <who>1</who>
          <who_name>jeff</who_name>
          <award>10</award>
          <when>
            <v t="T">2024-07-02T00:00:00Z</v>
            <v t="T">2024-07-03T00:00:00Z</v>
          </when>
        </f>
      </fb>
      ',
      'today' => '2024-07-05T00:00:00Z'
    )
    assert_equal(1, xml.xpath('//tbody/tr[not(@class)]').size, xml)
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
      3.3 => ['0.0', '+3.3'],
      0 => ['0.0', '+0.0'],
      -1 => ['0.0', '-1.0'],
      5.123 => ['0.0', '+5.1'],
      -2.456 => ['0.0', '-2.5'],
      0.0 => ['0.0', '+0.0'],
      10.5 => ['0.00', '+10.50'],
      -7.8 => ['0.00', '-7.80'],
      10.6 => ['0.00', '+10.60']
    }.each do |value, (format, expected)|
      xml = xslt("<r><xsl:value-of select=\"z:format-signed(#{value}, '#{format}')\"/></r>", '<fb/>')
      assert_equal(expected, xml.xpath('/r/text()').to_s, "Failed for value #{value} with format #{format}: #{xml}")
    end
  end

  def test_fn_format_signed_invalid_formats
    ['0', '0.000', '0.0000', 'invalid'].each do |invalid_format|
      assert_raises(StandardError) do
        xslt("<r><xsl:value-of select=\"z:format-signed(1.0, '#{invalid_format}')\"/></r>", '<fb/>')
      end
    end
  end

  def test_bylaws_responsive_columns_in_css
    f = File.join(__dir__, '../../target/css/main.css')
    skip("File not found:  #{f}") unless File.exist?(f)
    css = File.read(f).gsub(/\s+/, '')
    assert_includes(css, '.bylaws.columns{column-count:5}', 'Desktop layout broken')
    assert_includes(css, '@media(max-width:1280px){.bylaws.columns{column-count:2}}', 'Tablet layout broken')
    assert_includes(css, '@media(max-width:768px){.bylaws.columns{column-count:1}}', 'Phone layout broken')
  end

  def test_css_links_allow_pipe_in_url
    xml = xslt(
      <<~XSL,
        <r>
          <xsl:call-template name="css-links">
            <xsl:with-param name="links" select="'https://cdn.example.com/app.css?next=a|b|abc123'"/>
          </xsl:call-template>
        </r>
      XSL
      '<fb/>'
    )
    link = xml.xpath('/r/link').first
    refute_nil(link, xml)
    assert_equal('https://cdn.example.com/app.css?next=a|b', link['href'])
    assert_equal('sha384-abc123', link['integrity'])
  end

  def test_adless_page_does_not_name_zerocracy_in_its_description
    html = generate_vitals_html(adless: 'true')
    refute_match(/zerocracy/i, html[%r{<meta name="description".*?/>}m].to_s, html)
  end

  def test_favicon_points_to_the_logo
    assert_equal('x', Nokogiri::HTML(generate_vitals_html).xpath('//link[@rel="icon"]/@href').to_s)
  end

  private

  def generate_vitals_html(adless: 'false')
    saxon = File.join(__dir__, '../../target/saxon.jar')
    skip("Saxon not built at #{saxon}") unless File.exist?(saxon)
    Dir.mktmpdir do |dir|
      input = File.join(dir, 'input.xml')
      File.write(input, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <fb>
          <f>
            <when>2024-07-03T22:22:22Z</when>
            <what>quality-of-service</what>
            <n_composite>0.5</n_composite>
          </f>
          <f>
            <when>2024-07-01T22:22:22Z</when>
            <award>14</award>
            <who>526301</who>
            <where>github</where>
            <who_name>yegor256</who_name>
            <is_human>1</is_human>
            <why>test</why>
            <repository>777</repository>
          </f>
          <f>
            <who>526301</who>
            <what>who-has-name</what>
            <name>yegor256</name>
            <where>github</where>
            <when>2024-06-26T22:22:22Z</when>
          </f>
        </fb>
      XML
      output = File.join(dir, 'vitals.html')
      qbash(
        [
          "java -jar #{Shellwords.escape(saxon)}",
          "-s:#{Shellwords.escape(input)}",
          "-xsl:#{Shellwords.escape(File.join(__dir__, '../../xsl/vitals.xsl'))}",
          "-o:#{Shellwords.escape(output)}"
        ] + %w[
          today=2024-09-26T04:04:04Z
          name=test
          logo=x
          palette=classic
          url=https://example.com
          version=0.0.1
          latest-version=0.0.2
          fbe=0.0.50
          css-links=
          js-links=
          css=body{}
          js=
        ].push("adless=#{adless}").map { |p| Shellwords.escape(p) },
        stdout: fake_loog
      )
      File.read(output)
    end
  end
end
