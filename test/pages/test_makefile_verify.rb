# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative '../test__helper'

class TestMakefileVerify < Minitest::Test
  def test_verifies_generated_files_when_invoked_alone_or_in_parallel
    [%w[verify], %w[entry verify]].each do |targets|
      fixture do |dir|
        stdout, stderr, status = run_make(dir, targets)
        assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
        assert_path_exists(File.join(dir, 'verified'))
        assert_equal("run\n", File.read(File.join(dir, 'docker-calls')))
      end
    end
  end

  def test_does_not_verify_stale_files_after_generation_fails
    fixture do |dir|
      FileUtils.mkdir_p(File.join(dir, 'target/fb/pages'))
      %w[-vitals.html .html .xml .json .yaml].each do |suffix|
        File.write(File.join(dir, "target/fb/pages/simple#{suffix}"), '')
      end
      stdout, stderr, status = run_make(dir, %w[verify], 'PROBE_FAIL' => 'yes')
      refute_predicate(status, :success?, "#{stdout}\n#{stderr}")
      refute_path_exists(File.join(dir, 'verified'))
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
      File.open(File.join(dir, 'makes/verify.sh'), 'a') { |file| file.puts('touch verified') }
      File.write(
        File.join(dir, 'bin/docker'),
        <<~SH
          #!/usr/bin/env bash
          set -eu
          echo "$1" >> docker-calls
          test "${PROBE_FAIL:-no}" != yes
          sleep 0.1
          mkdir -p target/fb/pages
          for suffix in -vitals.html .html .xml .json .yaml; do
            touch "target/fb/pages/simple${suffix}"
          done
        SH
      )
      FileUtils.chmod(0o755, File.join(dir, 'bin/docker'))
      yield(dir)
    end
  end
end
