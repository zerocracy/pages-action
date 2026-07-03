# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'shellwords'
require_relative '../test__helper'

class TestBadge < Minitest::Test
  def test_validate_svg
    WebMock.enable_net_connect!
    f = File.join(__dir__, '../../target/html/simple-badge.svg')
    skip unless File.exist?(f)
    svg = File.read(f)
    xml =
      begin
        Nokogiri::XML.parse(svg) do |c|
          c.norecover
          c.strict
        end
      rescue StandardError => e
        raise("#{svg}\n\n#{e}")
      end
    assert_empty(xml.errors, svg)
    refute_empty(xml.xpath('/svg'), svg)
  end

  def test_shows_plus_zero_when_average_is_exactly_zero
    xml = badge_svg('<fb/>')
    texts = xml.xpath("//*[local-name()='text']").map(&:text)
    refute_includes(texts, '-0', "Badge with a zero average must not show a negative sign:\n#{xml}")
    assert_includes(texts, '+0', xml)
  end

  private

  def badge_svg(xml)
    Dir.mktmpdir do |dir|
      input = File.join(dir, 'input.xml')
      File.write(input, xml)
      output = File.join(dir, 'output.xml')
      qbash(
        [
          "java -jar #{Shellwords.escape(File.join(__dir__, '../../target/saxon.jar'))}",
          "-s:#{Shellwords.escape(input)}",
          "-xsl:#{Shellwords.escape(File.join(__dir__, '../../xsl/badge.xsl'))}",
          "-o:#{Shellwords.escape(output)}",
          'today=2024-01-01T00:00:00'
        ],
        stdout: fake_loog
      )
      Nokogiri::XML.parse(File.read(output))
    end
  end
end
