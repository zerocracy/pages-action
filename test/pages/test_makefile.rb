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

  def test_runs_stylelint_without_fixing_the_sources
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      FileUtils.mkdir_p(%w[bin sass].map { |path| File.join(dir, path) })
      File.write(File.join(dir, 'sass/main.scss'), '')
      File.write(File.join(dir, 'bin/stylelint'), "#!/usr/bin/env bash\necho \"$@\" > \"$(dirname \"$0\")/args\"\n")
      FileUtils.chmod(0o755, File.join(dir, 'bin/stylelint'))
      system(
        { 'PATH' => "#{dir}/bin:#{ENV.fetch('PATH')}" },
        'make', '-C', dir, 'stylelint', out: File::NULL, err: File::NULL
      )
      refute_includes(File.read(File.join(dir, 'bin/args')), '--fix', 'make lets stylelint rewrite the sources')
    end
  end

  def test_leaves_no_saxon_jar_behind_when_the_download_fails
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      FileUtils.mkdir_p(File.join(dir, 'bin'))
      File.write(
        File.join(dir, 'bin/wget'),
        "#!/usr/bin/env bash\nwhile [ $# -gt 0 ]; do [ \"$1\" = -O ] && : > \"$2\"; shift; done\nexit 4\n"
      )
      FileUtils.chmod(0o755, File.join(dir, 'bin/wget'))
      system(
        { 'HOME' => dir, 'PATH' => "#{dir}/bin:#{ENV.fetch('PATH')}" },
        'make', '-C', dir, 'target/saxon.jar', out: File::NULL, err: File::NULL
      )
      refute_path_exists(File.join(dir, 'target/saxon.jar'), 'a failed download left saxon.jar behind')
    end
  end

  def test_rebuilds_the_docker_image_after_a_stylesheet_changes
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      FileUtils.mkdir_p(%w[xsl target].map { |path| File.join(dir, path) })
      %w[Dockerfile entry.sh xsl/vitals.xsl Gemfile Gemfile.lock html-minifier-config.json].each do |file|
        File.write(File.join(dir, file), '')
        File.utime(Time.now - 100, Time.now - 100, File.join(dir, file))
      end
      File.utime(Time.now - 100, Time.now - 100, File.join(dir, 'Makefile'))
      File.write(File.join(dir, 'target/docker-image.txt'), 'x')
      File.utime(Time.now - 50, Time.now - 50, File.join(dir, 'target/docker-image.txt'))
      assert(system('make', '-C', dir, '-q', 'target/docker-image.txt', out: File::NULL, err: File::NULL), 'unchanged')
      File.utime(Time.now, Time.now, File.join(dir, 'xsl/vitals.xsl'))
      refute(system('make', '-C', dir, '-q', 'target/docker-image.txt', out: File::NULL, err: File::NULL))
    end
  end
end
