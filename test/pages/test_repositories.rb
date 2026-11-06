# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

class TestRepositories < Minitest::Test
  def test_sorts_repositories_ignoring_case
    names = %w[yegor256/factbase zerocracy/Zerocracy.github.io zerocracy/baza Yegor256/Tacit]
    facts = names.map { |n| "<f><what>repo-details</what><repository_name>#{n}</repository_name></f>" }.join
    xml = xslt("<r><xsl:apply-templates select='/' mode='repositories'/></r>", "<fb>#{facts}</fb>")
    assert_equal(
      %w[yegor256/factbase Yegor256/Tacit zerocracy/baza zerocracy/Zerocracy.github.io],
      xml.xpath('//li/a').map(&:text),
      xml
    )
  end

  def test_prints_the_day_of_the_last_update
    time = updated('2024-09-20T10:00:00Z').xpath('//time').first
    assert_equal('2024-09-20', time.text, 'the date text is not the day of the update')
  end

  def test_titles_the_time_with_the_day_of_the_last_update
    time = updated('2024-09-20T10:00:00Z').xpath('//time').first
    assert_equal('2024-09-20', time['title'], 'the tooltip is not the day of the update')
  end

  def test_keeps_the_full_moment_in_the_datetime
    time = updated('2024-09-20T10:00:00Z').xpath('//time').first
    assert_equal('2024-09-20T10:00:00Z', time['datetime'], 'the datetime lost its time')
  end

  def test_prints_no_time_without_an_update
    xml = updated('')
    assert_empty(xml.xpath('//time'), 'a time was printed for a repository without an update')
    refute_includes(xml.xpath('//li').text, 'updated', 'the word updated was printed without a date')
  end

  private

  def updated(stamp)
    xslt(
      "<r><xsl:apply-templates select='/' mode='repositories'/></r>",
      '<fb><f><what>repo-details</what><repository_name>foo/bar</repository_name>' \
      "<open_issues>1</open_issues><updated_at>#{stamp}</updated_at></f></fb>"
    )
  end
end
