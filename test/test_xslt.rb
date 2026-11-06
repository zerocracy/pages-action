# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'nokogiri'
require_relative 'test__helper'

class TestXslt < Minitest::Test
  def test_keeps_an_import_path_with_quotes_and_ampersands_valid
    path = "/tmp/pages'quote&amp"
    xml = Nokogiri::XML(xsl_document('', path), &:strict)
    assert_equal(
      path,
      xml.xpath('//xsl:import', 'xsl' => 'http://www.w3.org/1999/XSL/Transform').first['href'],
      'the import path did not round-trip'
    )
  end
end
