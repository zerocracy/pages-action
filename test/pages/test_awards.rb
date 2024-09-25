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
require 'nokogiri'
require 'qbash'
require 'loog'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestAwards < Minitest::Test
  def test_payables
    Dir.mktmpdir do |dir|
      xsl = File.join(dir, 'foo.xsl')
      File.write(
        xsl,
        "
        <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
          xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:z='https://www.zerocracy.com'
          version='2.0' exclude-result-prefixes='xs z'>
          <xsl:import href='#{File.join(__dir__, '../../xsl/vitals.xsl')}'/>
          <xsl:template match='/'>
            <xsl:copy-of select=\"z:payables('dude')\"/>
          </xsl:template>
        </xsl:stylesheet>
        "
      )
      xml = File.join(dir, 'input.xml')
      File.write(
        xml,
        "
        <fb>
          <f>
            <what>reconciliation</what>
            <when>#{(Time.now - (60 * 60)).utc.iso8601}</when>
            <since>#{(Time.now - (50 * 60 * 60)).utc.iso8601}</since>
            <who_name>dude</who_name>
            <awarded>100</awarded>
            <payout>70</payout>
            <balance>30</balance>
          </f>
          <f>
            <is_human>1</is_human>
            <when>#{(Time.now - (10 * 60 * 60)).utc.iso8601}</when>
            <who_name>dude</who_name>
            <award>40</award>
          </f>
          <f>
            <is_human>1</is_human>
            <when>#{(Time.now - (10 * 60 * 60)).utc.iso8601}</when>
            <who_name>dude</who_name>
            <award>60</award>
          </f>
          <f>
            <is_human>1</is_human>
            <when>#{Time.now.utc.iso8601}</when>
            <who_name>dude</who_name>
            <award>25</award>
          </f>
        </fb>
        "
      )
      output = File.join(dir, 'output.xml')
      qbash(
        [
          "java -jar #{Shellwords.escape(File.join(__dir__, '../../target/saxon.jar'))}",
          "-s:#{Shellwords.escape(xml)}",
          "-xsl:#{Shellwords.escape(xsl)}",
          "-o:#{Shellwords.escape(output)}",
          "today=#{Shellwords.escape((Time.now + 10).utc.iso8601)}"
        ],
        log: Loog::NULL
      )
      out = Nokogiri::XML.parse(File.read(output))
      assert_equal('55', out.xpath('/td/text()').to_s, out)
    end
  end
end
