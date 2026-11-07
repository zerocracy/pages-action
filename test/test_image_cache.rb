# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'find'
require 'open3'
require 'tmpdir'
require_relative 'test__helper'

class TestImageCache < Minitest::Test
  def test_rebuilds_after_a_judge_is_removed
    with_image do |dir|
      FileUtils.rm(File.join(dir, 'judges/copy-repo-names/copy-repo-names.rb'))
      assert_image_status(dir, 1)
    end
  end

  def test_rebuilds_after_a_judge_directory_is_removed
    with_image do |dir|
      FileUtils.rm_r(File.join(dir, 'judges/copy-repo-names'))
      assert_image_status(dir, 1)
    end
  end

  def test_rebuilds_after_a_javascript_source_is_removed
    with_image do |dir|
      FileUtils.rm(File.join(dir, 'js/clipboard.js'))
      assert_image_status(dir, 1)
    end
  end

  private

  def with_image
    Dir.mktmpdir do |dir|
      %w[
        Makefile Dockerfile entry.sh judges xsl js sass makes Gemfile Gemfile.lock
        html-minifier-config.json eslint.config.js .stylelintrc.json
      ].each { |path| FileUtils.cp_r(File.join(__dir__, '..', path), dir) }
      Find.find(dir) { |path| FileUtils.touch(path, mtime: Time.now - 120) }
      FileUtils.mkdir_p(File.join(dir, 'target'))
      marker = File.join(dir, 'target/docker-image.txt')
      File.write(marker, "test-image\n")
      FileUtils.touch(marker, mtime: Time.now - 60)
      assert_image_status(dir, 0)
      yield(dir)
    end
  end

  def assert_image_status(dir, expected)
    stdout, stderr, status = Open3.capture3('make', '-q', 'target/docker-image.txt', chdir: dir)
    assert_equal(expected, status.exitstatus, "#{stdout}\n#{stderr}")
  end
end
