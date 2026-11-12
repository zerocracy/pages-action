# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'open3'
require_relative 'test__helper'

class TestWriteSummary < Minitest::Test
  def test_appends_the_page_figures_and_publication_link
    text = summary_for('<meta property="og:url" content="https://example.org/report-vitals.html">')
    assert_includes(text, 'Existing summary')
    assert_includes(text, 'The &quot;project&quot; product: +4.3 average points per task, 13 total points earned.')
    assert_includes(text, '<a href="https://example.org/report-vitals.html">View published report</a>')
  end

  def test_omits_the_publication_link_for_a_local_report
    text = summary_for('')
    assert_includes(text, '13 total points earned.')
    refute_includes(text, '<a ')
  end

  private

  def summary_for(link)
    Dir.mktmpdir do |dir|
      input = File.join(dir, 'report.html')
      output = File.join(dir, 'summary.md')
      File.write(
        input, '<meta name="description" content="The &quot;project&quot; product: ' \
               "+4.3 average points per task, 13 total points earned.\">#{link}"
      )
      File.write(output, "Existing summary\n")
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby, File.expand_path('../makes/write-summary.rb', __dir__), input, output
      )
      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
      File.read(output)
    end
  end
end
