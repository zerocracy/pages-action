# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative '../test__helper'

class TestMakefileSources < Minitest::Test
  def test_reruns_judges_after_judge_or_library_source_changes
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      FileUtils.mkdir_p(
        %w[target/fb target/css target/js tests sass js judges/probe lib/nested].map { |path| File.join(dir, path) }
      )
      %w[
        target/fb/sample.fb tests/sample.yml target/css/main.css target/js/test.js
        target/saxon.jar sass/main.scss js/main.js tests/symbols.js
      ].each { |file| File.write(File.join(dir, file), '') }
      File.write("#{dir}/html-minifier-config.json", '{}')
      File.write("#{dir}/judges-probe", "#!/usr/bin/env bash\ntouch \"${@: -1}\"\n")
      File.write("#{dir}/lib/nested/value.rb", "VALUE = 'first'\n")
      File.write("#{dir}/judges/probe/probe.rb", "require_relative '../../lib/nested/value'\nputs VALUE\n")
      File.write(
        "#{dir}/entry.sh",
        <<~SH
          #!/usr/bin/env bash
          set -e
          mkdir -p "${INPUT_OUTPUT}"
          ruby judges/probe/probe.rb > "${INPUT_OUTPUT}/result.txt"
        SH
      )
      %w[entry.sh judges-probe].each { |file| FileUtils.chmod(0o755, File.join(dir, file)) }
      before = Time.now - 120
      Dir.glob("#{dir}/**/*").select { |file| File.file?(file) }.each do |file|
        File.utime(before, before, file)
      end
      command = [
        'make', '-C', dir, 'target/output/sample', 'XSLS=', 'JUDGES=./judges-probe',
        '-o', 'target/css/main.css', '-o', 'target/js/test.js', '-o', 'target/saxon.jar',
        '-o', 'stylelint', '-o', 'target/js/main.js'
      ]
      stdout, stderr, status = Open3.capture3(*command)
      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
      assert_equal("first\n", File.read("#{dir}/target/output/sample/result.txt"))
      [
        ['judges/probe/probe.rb', "require_relative '../../lib/nested/value'\nputs VALUE.upcase\n", "FIRST\n"],
        ['lib/nested/value.rb', "VALUE = 'second'\n", "SECOND\n"]
      ].each do |file, source, expected|
        File.utime(before + 10, before + 10, "#{dir}/target/fb/sample.fb")
        File.utime(before + 30, before + 30, "#{dir}/target/output/sample")
        File.write(File.join(dir, file), source)
        File.utime(before + 60, before + 60, File.join(dir, file))
        stdout, stderr, status = Open3.capture3(*command)
        assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
        assert_equal(expected, File.read("#{dir}/target/output/sample/result.txt"), file)
        File.utime(before, before, File.join(dir, file))
      end
    end
  end
end
