# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'json'
require_relative '../test__helper'

class TestRenovate < Minitest::Test
  def test_tracks_every_pinned_npm_build_tool
    config = JSON.parse(File.read(File.join(__dir__, '../../renovate.json')))
    manager = config.fetch('customManagers').find { |item| item['datasourceTemplate'] == 'npm' }
    expected = %w[@eslint/js eslint uglify-js sass html-minifier]
    %w[makes/install.sh .github/workflows/stylelint.yml].each do |path|
      assert(manager.fetch('managerFilePatterns').any? { |pattern| Regexp.new(pattern[1...-1]).match?(path) })
      packages = extract(manager, File.read(File.join(__dir__, '../..', path)))
      assert_includes(packages, 'stylelint')
      assert_includes(packages, 'stylelint-config-standard')
      next unless path.end_with?('.sh')
      expected.each { |name| assert_includes(packages, name) }
    end
  end

  def test_handles_multiple_and_scoped_packages_without_tracking_action_tags
    config = JSON.parse(File.read(File.join(__dir__, '../../renovate.json')))
    manager = config.fetch('customManagers').find { |item| item['datasourceTemplate'] == 'npm' }
    packages = extract(
      manager,
      "uses: actions/checkout@v7\nrun: npm install --global stylelint@17.14.0 @eslint/js@9.22.0\necho other@1.2.3\n"
    )
    assert_equal({ 'stylelint' => '17.14.0', '@eslint/js' => '9.22.0' }, packages)
  end

  private

  def extract(manager, source)
    lines, dependencies = manager.fetch('matchStrings').map { |pattern| Regexp.new(pattern) }
    source.scan(lines).flat_map { |line| line.scan(dependencies) }.to_h
  end
end
