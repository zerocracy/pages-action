# frozen_string_literal: true

# MIT License
#
# Copyright (c) 2024 Zerocracy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'webmock/minitest'
require 'nokogiri'
require 'w3c_validators'
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
    assert(xml.errors.empty?, xml)
    assert(!xml.xpath('/html').empty?, xml)
    # WebMock.enable_net_connect!
    # v = W3CValidators::NuValidator.new.validate_file(html)
    # assert(v.errors.empty?, "#{doc}\n\n#{v.errors.join('; ')}")
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
