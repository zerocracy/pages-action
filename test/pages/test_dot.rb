# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'nokogiri'
require_relative '../test__helper'

class TestDot < Minitest::Test
  def test_shows_measure_taken_exactly_at_today_in_last_cell
    assert_equal(%w[2 3], cells(dot_table, 'average_stars').last(2), 'the measure at today is missing')
  end

  def test_gives_every_row_as_many_cells_as_the_header
    xml = dot_table
    heads = xml.xpath('//thead/tr/th').size
    xml.xpath('//tbody/tr').each do |tr|
      assert_equal(heads, tr.xpath('td').size, "the row #{tr.xpath('td[1]').text} has a wrong number of cells")
    end
  end

  def test_sorts_rows_by_dimension_name
    names = dot_table.xpath('//tbody/tr/td[1]').map { |td| td.text.strip }
    assert_equal(%w[average_stars total_repos], names, 'the rows are not in alphabetical order')
  end

  def test_puts_older_measure_into_its_own_week
    assert_equal(['', '', '6', '7'], cells(dot_table, 'total_repos'), 'the measure of 2024-09-18 moved')
  end

  private

  def dot_table
    xslt(
      "<r><xsl:apply-templates select='/' mode='dot'/></r>",
      '<fb><f><what>dimensions-of-terrain</what><when>2024-09-18T10:00:00Z</when>' \
      '<total_repos>6</total_repos><average_stars>2</average_stars></f>' \
      '<f><what>dimensions-of-terrain</what><when>2024-09-26T04:04:04Z</when>' \
      '<total_repos>7</total_repos><average_stars>3</average_stars></f></fb>',
      'today' => '2024-09-26T04:04:04Z'
    )
  end

  def cells(xml, name)
    xml.xpath("//tbody/tr[td[1]='#{name}']/td[position() > 1]").map { |td| td.text.strip }
  end
end
