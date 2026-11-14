# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative '../test__helper'

class TestMakefileRmi < Minitest::Test
  def test_cleanup_waits_for_entry
    fixture do |dir|
      stdout, stderr, status = run_make(dir, %w[entry rmi])
      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
      assert_equal("run\nrmi\n", File.read(File.join(dir, 'docker-calls')))
    end
  end

  def test_cleanup_keeps_identifier_as_first_prerequisite
    fixture do |dir|
      stdout, stderr, status = run_make(dir, %w[entry rmi])
      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
      assert_equal("run\nrmi\n", File.read(File.join(dir, 'docker-calls')))
      refute_path_exists(File.join(dir, 'target/docker-image.txt'))
      refute_path_exists(File.join(dir, 'image-present'))
    end
  end

  def test_skips_cleanup_when_entry_fails
    fixture do |dir|
      stdout, stderr, status = run_make(dir, %w[entry rmi], 'PROBE_FAIL' => 'yes')
      refute_predicate(status, :success?, "#{stdout}\n#{stderr}")
      assert_equal("run\n", File.read(File.join(dir, 'docker-calls')))
      assert_path_exists(File.join(dir, 'image-present'))
      assert_path_exists(File.join(dir, 'target/docker-image.txt'))
    end
  end

  def test_cleanup_alone_runs_entry_first
    fixture do |dir|
      stdout, stderr, status = run_make(dir, %w[rmi])
      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
      assert_equal("run\nrmi\n", File.read(File.join(dir, 'docker-calls')))
    end
  end

  private

  def run_make(dir, targets, env = {})
    Open3.capture3(
      { 'PATH' => "#{dir}/bin:#{ENV.fetch('PATH')}" }.merge(env),
      'make', '-C', dir, '-j2', '-o', 'target/docker-image.txt', '-o', 'target/fb/simple.fb', *targets
    )
  end

  def fixture
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '../../Makefile'), dir)
      FileUtils.cp_r(File.join(__dir__, '../../makes'), dir)
      FileUtils.mkdir_p(%w[bin target/fb].map { |path| File.join(dir, path) })
      File.write(File.join(dir, 'target/docker-image.txt'), "probe-image\n")
      File.write(File.join(dir, 'target/fb/simple.fb'), '')
      File.write(File.join(dir, 'image-present'), '')
      File.write(
        File.join(dir, 'bin/docker'),
        <<~SH
          #!/usr/bin/env bash
          set -eu
          printf '%s\\n' "$1" >> docker-calls
          case "$1" in
            run)
              sleep 0.3
              test "${PROBE_FAIL:-no}" != yes
              test -e image-present
              ;;
            rmi)
              rm image-present
              ;;
            *) exit 50 ;;
          esac
        SH
      )
      FileUtils.chmod(0o755, File.join(dir, 'bin/docker'))
      yield(dir)
    end
  end
end
