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

  def test_links_every_repository_to_github
    facts = %w[yegor256/factbase zerocracy/baza].map do |n|
      "<f><what>repo-details</what><repository_name>#{n}</repository_name></f>"
    end
    xml = xslt("<r><xsl:apply-templates select='/' mode='repositories'/></r>", "<fb>#{facts.join}</fb>")
    assert_equal(
      %w[https://github.com/yegor256/factbase https://github.com/zerocracy/baza],
      xml.xpath('//li/a/@href').map(&:value),
      xml
    )
  end

  def test_skips_empty_description_and_language
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='repositories'/></r>",
      '<fb><f><what>repo-details</what><repository_name>foo/bar</repository_name>' \
      '<description></description><language></language><stars>1</stars><forks>0</forks>' \
      '<open_issues>0</open_issues></f></fb>'
    )
    assert_equal(
      'foo/bar [ 1 star · 0 forks · 0 open issues and pull requests ]',
      xml.xpath('//li').first.text,
      xml
    )
  end
end
