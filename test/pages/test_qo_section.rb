# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'English'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestQoSection < Minitest::Test
  def test_snake_case_to_title
    xml = xslt(
      '<r><xsl:value-of select="z:snake-case-to-title(\'average_issue_lifetime\')"/></r>',
      '
      <fb>
        <f>
          <when>2024-08-03T22:22:22.8492Z</when>
          <what>quality-of-service</what>
        </f>
      </fb>
      ',
      'today' => '2024-09-26T04:04:04Z'
    )
    assert_equal('Average Issue Lifetime', xml.xpath('//r/text()').to_s.strip)
  end

  def test_iso_week_regular
    xml = xslt(
      '<r><xsl:value-of select="z:iso-week(xs:dateTime(\'2024-07-15T00:00:00Z\'))"/></r>',
      '<fb/>'
    )
    assert_equal('2024-W29', xml.xpath('//r/text()').to_s.strip)
  end

  def test_iso_week_year_boundary_dec31
    xml = xslt(
      '<r><xsl:value-of select="z:iso-week(xs:dateTime(\'2023-12-31T00:00:00Z\'))"/></r>',
      '<fb/>'
    )
    assert_equal('2023-W52', xml.xpath('//r/text()').to_s.strip)
  end

  def test_iso_week_jan1
    xml = xslt(
      '<r><xsl:value-of select="z:iso-week(xs:dateTime(\'2024-01-01T00:00:00Z\'))"/></r>',
      '<fb/>'
    )
    assert_equal('2024-W01', xml.xpath('//r/text()').to_s.strip)
  end

  def test_iso_week_dec25
    xml = xslt(
      '<r><xsl:value-of select="z:iso-week(xs:dateTime(\'2023-12-25T00:00:00Z\'))"/></r>',
      '<fb/>'
    )
    assert_equal('2023-W52', xml.xpath('//r/text()').to_s.strip)
  end

  def test_iso_week_friday
    xml = xslt(
      '<r><xsl:value-of select="z:iso-week(xs:dateTime(\'2023-12-29T00:00:00Z\'))"/></r>',
      '<fb/>'
    )
    assert_equal('2023-W52', xml.xpath('//r/text()').to_s.strip)
  end

  def test_iso_week_saturday
    xml = xslt(
      '<r><xsl:value-of select="z:iso-week(xs:dateTime(\'2023-12-30T00:00:00Z\'))"/></r>',
      '<fb/>'
    )
    assert_equal('2023-W52', xml.xpath('//r/text()').to_s.strip)
  end

  def test_iso_week_sunday_dec31_two_thousand_twenty_four
    xml = xslt(
      '<r><xsl:value-of select="z:iso-week(xs:dateTime(\'2024-12-29T00:00:00Z\'))"/></r>',
      '<fb/>'
    )
    assert_equal('2024-W52', xml.xpath('//r/text()').to_s.strip)
  end

  def test_inline_js_syntax_in_generated_html
    xml = xslt(
      "<r><xsl:call-template name='qo-section'>" \
      "<xsl:with-param name='what' select=\"'quality-of-service'\"/>" \
      "<xsl:with-param name='title' select=\"'QoS'\"/>" \
      '</xsl:call-template></r>',
      '<fb>
        <f>
          <when>2024-07-03T22:22:22Z</when>
          <what>quality-of-service</what>
          <n_composite>0.5</n_composite>
          <n_average_issue_lifetime>-0.3</n_average_issue_lifetime>
        </f>
        <f>
          <when>2024-06-23T22:22:22Z</when>
          <what>quality-of-service</what>
          <n_composite>0.8</n_composite>
          <n_average_issue_lifetime>0.1</n_average_issue_lifetime>
        </f>
      </fb>',
      'today' => '2024-09-26T04:04:04Z'
    )
    scripts = xml.xpath('//script[not(@src)]').map { |s| s.content.strip }.reject(&:empty?)
    refute_empty(scripts, 'Expected non-empty inline scripts to be generated')
    scripts.each_with_index do |js, idx|
      Dir.mktmpdir do |dir|
        file = File.join(dir, "test_#{idx}.js")
        File.write(file, js)
        output = `node --check #{Shellwords.escape(file)} 2>&1`
        assert_predicate(
          $CHILD_STATUS, :success?,
          "JS syntax error in script ##{idx}: #{$CHILD_STATUS}\n#{output}\nContent: #{js}"
        )
      end
    end
  end
end
