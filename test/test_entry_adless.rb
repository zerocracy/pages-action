# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'English'
require 'factbase'
require 'fileutils'
require 'tmpdir'
require_relative 'test__helper'

class TestEntryAdless < Minitest::Test
  def test_removes_zerocracy_branding_from_the_html_dump
    saxon = File.join(__dir__, '../target/saxon.jar')
    skip("Saxon not built at #{saxon}") unless File.exist?(saxon)
    script = File.read(File.join(__dir__, '..', 'entry.sh'))[
      /^if \[ "\$\{INPUT_ADLESS\}" == 'true' \]; then\n(?:.*\n)*?.*adless\.html.*\n(?:.*\n)*?fi\n/
    ]
    refute_nil(script, 'No adless handling of the HTML dump found in entry.sh')
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'target/xsl'))
      FileUtils.cp(saxon, File.join(dir, 'target/saxon.jar'))
      FileUtils.cp(File.join(__dir__, '../xsl/adless.xsl'), File.join(dir, 'target/xsl/adless.xsl'))
      fb = Factbase.new
      fb.insert.what = 'probe'
      File.binwrite(File.join(dir, 'probe.fb'), fb.export)
      html = File.join(dir, 'probe.html')
      qbash("judges print --format html #{Shellwords.escape(File.join(dir, 'probe.fb'))} #{Shellwords.escape(html)}")
      assert_match(/zerocracy\.com/, File.read(html), 'the judges dump has no Zerocracy branding to remove')
      out = IO.popen(
        { 'INPUT_ADLESS' => 'true', 'SELF' => dir, 'staging' => dir, 'name' => 'probe' },
        ['bash', '-e', '-c', script], err: %i[child out], &:read
      )
      assert_predicate($CHILD_STATUS, :success?, out)
      refute_match(/zerocracy/i, File.read(html), File.read(html))
      assert_includes(File.read(html), 'probe', File.read(html))
    end
  end
end
