# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'json'
require_relative '../test__helper'

class TestVitalsSummary < Minitest::Test
  def test_summarizes_only_awards_in_the_page_window
    summary, html = render_summary(
      '<f><when>2026-03-01T00:00:00Z</when><award>100</award><who>1</who></f>' \
      '<f><when>2026-11-01T00:00:00Z</when><award>14</award><who>2</who></f>' \
      '<f><when>2026-11-02T00:00:00Z</when><award>-5</award><who>2</who></f>' \
      '<f><when>2026-11-12T00:00:00Z</when><award>4</award><who>3</who></f>' \
      '<f><when>2026-11-13T00:00:00Z</when><award>200</award><who>4</who></f>'
    )
    assert_equal(
      {
        'average_award' => 4.3, 'total_award' => 13, 'contributors' => 2, 'count' => 3,
        'since' => '2026-03-01T00:00:00Z', 'until' => '2026-11-12T00:00:00Z'
      }, summary
    )
    assert_includes(html, '+4.3 average points per task, 13 total points earned, 2 contributors.')
  end

  def test_rounds_a_negative_average_like_the_page
    summary, html = render_summary(
      '<f><when>2026-11-01T00:00:00Z</when><award>-1</award><who>1</who></f>' \
      '<f><when>2026-11-02T00:00:00Z</when><award>-2</award><who>1</who></f>' \
      '<f><when>2026-11-03T00:00:00Z</when><award>-1</award><who>1</who></f>'
    )
    assert_in_delta(-1.3, summary.fetch('average_award'))
    assert_includes(html, '-1.3 average points per task, -4 total points earned, 1 contributor.')
  end

  def test_rounds_fractional_total_points_like_the_page
    summary, html = render_summary(
      '<f><when>2026-11-01T00:00:00Z</when><award>1.25</award><who>1</who></f>' \
      '<f><when>2026-11-02T00:00:00Z</when><award>1.25</award><who>1</who></f>'
    )
    assert_equal(2, summary.fetch('total_award'))
    assert_includes(html, '+1.3 average points per task, 2 total points earned, 1 contributor.')
  end

  def test_summarizes_an_empty_page_without_nonfinite_numbers
    summary, html = render_summary('')
    assert_equal([0, 0, 0, 0], summary.values_at('average_award', 'total_award', 'contributors', 'count'))
    assert_includes(html, '+0.0 average points per task, 0 total points earned, 0 contributors.')
  end

  private

  def render_summary(facts)
    Dir.mktmpdir do |dir|
      input = File.join(dir, 'input.xml')
      output = File.join(dir, 'vitals.html')
      File.write(input, "<fb>#{facts}</fb>")
      qbash(
        [
          "java -jar #{Shellwords.escape(File.join(__dir__, '../../target/saxon.jar'))}",
          "-s:#{Shellwords.escape(input)}",
          "-xsl:#{Shellwords.escape(File.join(__dir__, '../../xsl/vitals.xsl'))}",
          "-o:#{Shellwords.escape(output)}"
        ] + %w[
          summary-output=vitals.json today=2026-11-12T00:00:00Z name=test
          logo= url= version=0.0.1 latest-version=0.0.1 fbe=0.0.50
          adless=true css-links= js-links= css= js=
        ].map { |arg| Shellwords.escape(arg) },
        stdout: fake_loog
      )
      [JSON.parse(File.read(File.join(dir, 'vitals.json'))), File.read(output)]
    end
  end
end
