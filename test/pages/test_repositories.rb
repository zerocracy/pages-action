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
end
