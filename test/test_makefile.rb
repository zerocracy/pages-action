# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative 'test__helper'

class TestMakefile < Minitest::Test
  def test_rebuilds_the_image_when_the_version_changes
    assert_includes(builds(%w[1.2.3 2.0.0]), 'VERSION=2.0.0')
  end

  def test_keeps_the_image_when_the_version_stays
    assert_equal(%w[VERSION=1.2.3 VERSION=1.2.3], builds(%w[1.2.3 1.2.3]))
  end

  private

  def builds(versions)
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(__dir__, '..', 'Makefile'), dir)
      %w[Dockerfile entry.sh Gemfile Gemfile.lock html-minifier-config.json].each do |f|
        FileUtils.touch(File.join(dir, f))
      end
      FileUtils.mkdir(File.join(dir, 'bin'))
      File.write(File.join(dir, 'bin', 'docker'), "#!/bin/sh\necho \"$3\" >> \"#{dir}/log\"\necho sha\n")
      File.chmod(0o755, File.join(dir, 'bin', 'docker'))
      versions.each do |v|
        _, stderr, status = Open3.capture3(
          { 'PATH' => "#{dir}/bin:#{ENV.fetch('PATH')}", 'MAKEFLAGS' => nil, 'MAKELEVEL' => nil },
          'make', '-C', dir, 'target/docker-image.txt', "PAGES_ACTION_VERSION=#{v}"
        )
        assert_predicate(status, :success?, stderr)
      end
      File.readlines(File.join(dir, 'log'), chomp: true)
    end
  end
end
