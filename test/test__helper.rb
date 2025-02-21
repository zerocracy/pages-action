# frozen_string_literal: true

# MIT License
#
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

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
