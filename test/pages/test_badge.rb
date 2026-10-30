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
    assert_path_exists(f, 'make did not put the badge next to the pages')
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
    refute_empty(xml.xpath("/*[local-name()='svg']"), svg)
  end

  def test_shows_plus_zero_when_average_is_exactly_zero
    xml = badge_svg('<fb/>')
    texts = xml.xpath("//*[local-name()='text']").map(&:text)
    refute_includes(texts, '-0', "Badge with a zero average must not show a negative sign:\n#{xml}")
    assert_includes(texts, '+0.0', xml)
  end

  def test_hides_logo_when_adless
    xml = badge_svg('<fb/>', 'adless=true')
    assert_empty(xml.xpath("//*[local-name()='g'][@transform]"), xml)
  end

  def test_shows_logo_when_not_adless
    xml = badge_svg('<fb/>', 'adless=false')
    refute_empty(xml.xpath("//*[local-name()='g'][@transform]"), xml)
  end

  def test_shows_one_decimal_for_a_whole_average
    xml = badge_svg(
      "
      <fb>
        <f><award>4</award><when>2023-12-01T00:00:00Z</when></f>
        <f><award>4</award><when>2023-12-02T00:00:00Z</when></f>
      </fb>
      "
    )
    texts = xml.xpath("//*[local-name()='text']").map(&:text)
    assert_includes(texts, '+4.0', xml)
  end

  def test_rounds_a_half_away_from_zero
    xml = badge_svg(
      "<fb>#{[12, 13, 12, 12].map { |a| "<f><award>#{a}</award><when>2023-12-01T00:00:00Z</when></f>" }.join}</fb>"
    )
    assert_includes(xml.xpath("//*[local-name()='text']").map(&:text), '+12.3', xml)
  end

  def test_shows_no_minus_for_an_average_rounded_to_zero
    awards = Array.new(96) { 8 } + Array.new(97) { -8 }
    xml = badge_svg(
      "<fb>#{awards.map { |a| "<f><award>#{a}</award><when>2023-12-01T00:00:00Z</when></f>" }.join}</fb>"
    )
    refute_includes(xml.xpath("//*[local-name()='text']").map(&:text), '-0.0', xml)
  end

  def test_counts_an_award_made_exactly_at_today
    xml = badge_svg('<fb><f><award>9</award><when>2024-01-01T00:00:00</when></f></fb>')
    texts = xml.xpath("//*[local-name()='text']").map(&:text)
    refute_includes(texts, '+0.0', xml)
    assert_includes(texts, '+9.0', xml)
  end

  def test_skips_an_award_made_after_today
    xml = badge_svg(
      '<fb><f><award>9</award><when>2024-01-01T00:00:01</when></f>' \
      '<f><award>3</award><when>2023-12-31T00:00:00Z</when></f></fb>'
    )
    assert_includes(xml.xpath("//*[local-name()='text']").map(&:text), '+3.0', xml)
  end

  def test_rounds_an_average_that_is_not_a_multiple_of_five_hundredths
    awards = [1, 0, 0, 0, 0, 0, 0]
    xml = badge_svg(
      "<fb>#{awards.map { |a| "<f><award>#{a}</award><when>2023-12-01T00:00:00Z</when></f>" }.join}</fb>"
    )
    assert_includes(xml.xpath("//*[local-name()='text']").map(&:text), '+0.1', xml)
  end

  def test_rounds_an_average_of_two_thirds
    awards = [1, 1, 0]
    xml = badge_svg(
      "<fb>#{awards.map { |a| "<f><award>#{a}</award><when>2023-12-01T00:00:00Z</when></f>" }.join}</fb>"
    )
    assert_includes(xml.xpath("//*[local-name()='text']").map(&:text), '+0.7', xml)
  end

  private

  def badge_svg(xml, *params)
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
          'today=2024-01-01T00:00:00',
          *params
        ],
        stdout: fake_loog
      )
      Nokogiri::XML.parse(File.read(output))
    end
  end
end
