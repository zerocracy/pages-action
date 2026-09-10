# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative '../test__helper'

class TestMakefileValidation < Minitest::Test
  def test_reruns_changed_xpath_even_when_output_directory_timestamp_is_unchanged
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      FileUtils.mkdir_p(%w[target/fb target/css target/js tests sass js].map { |path| File.join(dir, path) })
      %w[
        target/fb/sample.fb target/css/main.css target/js/test.js target/saxon.jar
        sass/main.scss js/main.js tests/symbols.js
      ].each do |file|
        File.write(File.join(dir, file), '')
      end
      File.write("#{dir}/html-minifier-config.json", '{}')
      File.write("#{dir}/tests/sample.yml", "- xpaths: /html/body/p\n")
      File.write("#{dir}/judges-probe", "#!/usr/bin/env bash\ntouch \"${@: -1}\"\n")
      File.write(
        "#{dir}/entry.sh",
        <<~SH
          #!/usr/bin/env bash
          set -e
          mkdir -p "${INPUT_OUTPUT}"
          for name in sample sample-vitals; do
              echo '<!DOCTYPE html><html><head><title>Probe</title></head><body><p>ok</p></body></html>' > "${INPUT_OUTPUT}/${name}.html"
          done
        SH
      )
      %w[entry.sh judges-probe].each { |file| FileUtils.chmod(0o755, File.join(dir, file)) }
      before = Time.now - 120
      Dir.glob("#{dir}/**/*").select { |file| File.file?(file) }.each do |file|
        File.utime(before, before, file)
      end
      command = [
        'make', '-C', dir, 'target/html/sample.html', 'XSLS=', 'JUDGES=./judges-probe',
        '-o', 'target/css/main.css', '-o', 'target/js/test.js', '-o', 'target/saxon.jar',
        '-o', 'stylelint', '-o', 'target/js/main.js'
      ]
      stdout, stderr, status = Open3.capture3(*command)
      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
      {
        'target/output/sample' => 20, 'target/html/sample.html' => 30,
        'target/html/sample-vitals.html' => 30, 'target/fb/sample.fb' => 10
      }.each do |file, offset|
        File.utime(before + offset, before + offset, File.join(dir, file))
      end
      File.write("#{dir}/tests/sample.yml", "- xpaths: /html/body/missing\n")
      File.utime(before + 60, before + 60, "#{dir}/tests/sample.yml")
      stdout, stderr, status = Open3.capture3(*command)
      refute_predicate(status, :success?, "Changed XPath was not checked: #{stdout}\n#{stderr}")
      assert_includes(stderr, 'XPath set is empty')
    end
  end
end
