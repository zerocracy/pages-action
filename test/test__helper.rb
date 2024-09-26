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

ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start

require 'simplecov-cobertura'
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

require 'judges/options'
require 'loog'
require 'minitest/autorun'
require 'nokogiri'
require 'qbash'
require 'shellwords'

class Minitest::Test
  def load_it(judge, fb)
    $fb = fb
    $global = {}
    $local = {}
    $judge = judge
    $options = Judges::Options.new({ 'repositories' => 'foo/foo' })
    $loog = Loog::NULL
    load(File.join(__dir__, "../judges/#{judge}/#{judge}.rb"))
  end

  def stub_github(url, body:, method: :get, status: 200, headers: { 'content-type': 'application/json' })
    stub_request(method, url).to_return(status:, body: body.to_json, headers:)
  end

  def fake_loog
    ENV['RACK_RUN'] ? Loog::NULL : Loog::VERBOSE
  end

  def xslt(template, xml, vars = {})
    Dir.mktmpdir do |dir|
      xsl = File.join(dir, 'foo.xsl')
      File.write(
        xsl,
        "
        <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
          xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:z='https://www.zerocracy.com'
          version='2.0' exclude-result-prefixes='xs z'>
          <xsl:import href='#{File.join(__dir__, '../xsl/vitals.xsl')}'/>
          <xsl:template match='/'>#{template}</xsl:template>
        </xsl:stylesheet>
        "
      )
      input = File.join(dir, 'input.xml')
      File.write(input, xml)
      output = File.join(dir, 'output.xml')
      qbash(
        [
          "java -jar #{Shellwords.escape(File.join(__dir__, '../target/saxon.jar'))}",
          "-s:#{Shellwords.escape(input)}",
          "-xsl:#{Shellwords.escape(xsl)}",
          "-o:#{Shellwords.escape(output)}"
        ] + vars.map { |k, v| Shellwords.escape("#{k}=#{v}") },
        log: fake_loog
      )
      Nokogiri::XML.parse(File.read(output))
    end
  end
end
