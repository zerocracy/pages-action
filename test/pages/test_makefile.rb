# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
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

  def test_downloads_saxon_before_running_the_entries
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      stdout, = Open3.capture2('make', '-n', '-C', dir, 'entries', '-o', 'assets')
      assert_includes(stdout, 'Saxon-HE', stdout)
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
      %w[
        Dockerfile entry.sh xsl/vitals.xsl Gemfile Gemfile.lock html-minifier-config.json
        eslint.config.js .stylelintrc.json
      ].each do |file|
        File.write(File.join(dir, file), '')
        File.utime(Time.now - 100, Time.now - 100, File.join(dir, file))
      end
      File.utime(Time.now - 100, Time.now - 100, File.join(dir, 'Makefile'))
      File.write(File.join(dir, 'target/version.txt'), "0.0.0\n")
      File.utime(Time.now - 100, Time.now - 100, File.join(dir, 'target/version.txt'))
      File.write(File.join(dir, 'target/docker-image.txt'), 'x')
      File.utime(Time.now - 50, Time.now - 50, File.join(dir, 'target/docker-image.txt'))
      assert_empty(builds(dir, '0.0.0'), 'the image is rebuilt while nothing changes')
      File.utime(Time.now, Time.now, File.join(dir, 'xsl/vitals.xsl'))
      refute_empty(builds(dir, '0.0.0'), 'the image is not rebuilt after the stylesheet changes')
    end
  end

  def test_lints_the_scripts_again_after_the_eslint_configuration_changes
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      FileUtils.mkdir_p(%w[js target/js].map { |path| File.join(dir, path) })
      %w[Makefile js/main.js eslint.config.js].each do |file|
        File.write(File.join(dir, file), '') unless file == 'Makefile'
        File.utime(Time.now - 100, Time.now - 100, File.join(dir, file))
      end
      File.write(File.join(dir, 'target/js/main.js'), 'x')
      File.utime(Time.now - 50, Time.now - 50, File.join(dir, 'target/js/main.js'))
      assert(system('make', '-C', dir, '-q', 'target/js/main.js', out: File::NULL, err: File::NULL), 'unchanged')
      File.utime(Time.now, Time.now, File.join(dir, 'eslint.config.js'))
      refute(system('make', '-C', dir, '-q', 'target/js/main.js', out: File::NULL, err: File::NULL))
    end
  end

  def test_rebuilds_the_docker_image_after_a_lint_configuration_changes
    files = %w[
      Makefile Dockerfile entry.sh Gemfile Gemfile.lock html-minifier-config.json
      eslint.config.js .stylelintrc.json
    ]
    %w[eslint.config.js .stylelintrc.json].each do |config|
      Dir.mktmpdir do |dir|
        FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
        FileUtils.mkdir_p(File.join(dir, 'target'))
        files.each do |file|
          File.write(File.join(dir, file), '') unless file == 'Makefile'
          File.utime(Time.now - 100, Time.now - 100, File.join(dir, file))
        end
        File.write(File.join(dir, 'target/version.txt'), "0.0.0\n")
        File.utime(Time.now - 100, Time.now - 100, File.join(dir, 'target/version.txt'))
        File.write(File.join(dir, 'target/docker-image.txt'), 'x')
        File.utime(Time.now - 50, Time.now - 50, File.join(dir, 'target/docker-image.txt'))
        assert_empty(builds(dir, '0.0.0'), "the image is stale before #{config} changes")
        File.utime(Time.now, Time.now, File.join(dir, config))
        refute_empty(builds(dir, '0.0.0'), "the image is not rebuilt after #{config} changes")
      end
    end
  end

  def test_rebuilds_the_docker_image_after_the_version_changes
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      %w[
        Dockerfile entry.sh Gemfile Gemfile.lock html-minifier-config.json
        eslint.config.js .stylelintrc.json
      ].each do |file|
        File.write(File.join(dir, file), '')
      end
      builds(dir, '1.2.3')
      assert_includes(builds(dir, '2.0.0'), 'VERSION=2.0.0', 'the image is not rebuilt after the version changes')
    end
  end

  def test_keeps_the_docker_image_while_the_version_stays
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      %w[
        Dockerfile entry.sh Gemfile Gemfile.lock html-minifier-config.json
        eslint.config.js .stylelintrc.json
      ].each do |file|
        File.write(File.join(dir, file), '')
      end
      builds(dir, '1.2.3')
      assert_empty(builds(dir, '1.2.3'), 'the image is rebuilt while the version stays')
    end
  end

  private

  def builds(dir, version)
    FileUtils.mkdir_p(File.join(dir, 'bin'))
    File.write(File.join(dir, 'bin/docker'), "#!/usr/bin/env bash\necho \"$3\" >> \"$(dirname \"$0\")/log\"\n")
    FileUtils.chmod(0o755, File.join(dir, 'bin/docker'))
    FileUtils.rm_f(File.join(dir, 'bin/log'))
    _, stderr, status = Open3.capture3(
      { 'PATH' => "#{dir}/bin:#{ENV.fetch('PATH')}", 'MAKEFLAGS' => nil, 'MAKELEVEL' => nil },
      'make', '-C', dir, 'target/docker-image.txt', "PAGES_ACTION_VERSION=#{version}"
    )
    assert_predicate(status, :success?, stderr)
    File.exist?(File.join(dir, 'bin/log')) ? File.readlines(File.join(dir, 'bin/log'), chomp: true) : []
  end
end
