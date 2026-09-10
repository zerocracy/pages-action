# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'tmpdir'
require_relative '../test__helper'

class TestMakefile < Minitest::Test
  def test_regenerates_output_when_minifier_configuration_changes
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      FileUtils.mkdir_p(%w[target/fb target/css target/js tests sass js].map { |path| File.join(dir, path) })
      %w[
        target/fb/sample.fb tests/sample.yml target/css/main.css target/js/test.js
        target/saxon.jar sass/main.scss js/main.js tests/symbols.js
      ].each do |file|
        File.write(File.join(dir, file), '')
      end
      File.write("#{dir}/html-minifier-config.json", '{"collapseWhitespace":false}')
      File.write(
        "#{dir}/entry.sh",
        <<~SH
          #!/usr/bin/env bash
          set -e
          mkdir -p "${INPUT_OUTPUT}"
          cp html-minifier-config.json "${INPUT_OUTPUT}/used-config.json"
        SH
      )
      FileUtils.chmod(0o755, "#{dir}/entry.sh")
      before = Time.now - 120
      Dir.glob("#{dir}/**/*").select { |file| File.file?(file) }.each do |file|
        File.utime(before, before, file)
      end
      command = [
        'make', '-C', dir, 'target/output/sample', 'XSLS=',
        '-o', 'target/css/main.css', '-o', 'target/js/test.js', '-o', 'target/saxon.jar',
        '-o', 'stylelint', '-o', 'target/js/main.js'
      ]
      qbash(command, stdout: fake_loog)
      output = "#{dir}/target/output/sample"
      assert_equal('{"collapseWhitespace":false}', File.read("#{output}/used-config.json"))
      File.utime(before + 30, before + 30, output)
      File.write("#{dir}/html-minifier-config.json", '{"collapseWhitespace":true}')
      File.utime(before + 60, before + 60, "#{dir}/html-minifier-config.json")
      qbash(command, stdout: fake_loog)
      assert_equal('{"collapseWhitespace":true}', File.read("#{output}/used-config.json"))
    end
  end
end
