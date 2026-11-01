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

  def test_counts_one_and_two_of_each_thing
    facts =
      %w[1 2].map do |n|
        "<f><what>repo-details</what><repository_name>foo/r#{n}</repository_name>" \
          "<stars>#{n}</stars><forks>#{n}</forks><open_issues>#{n}</open_issues></f>"
      end
    xml = xslt("<r><xsl:apply-templates select='/' mode='repositories'/></r>", "<fb>#{facts.join}</fb>")
    assert_equal(
      [
        'foo/r1 [ 1 star · 1 fork · 1 open issue or pull request ]',
        'foo/r2 [ 2 stars · 2 forks · 2 open issues and pull requests ]'
      ],
      xml.xpath('//li').map { |li| li.text.strip },
      xml
    )
  end
end
