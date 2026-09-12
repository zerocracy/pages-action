# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require 'fbe/fb'
require 'fbe/octo'
require_relative '../test__helper'

class TestCopyRepoNames < Minitest::Test
  def test_refreshes_existing_repository_details
    fb = Factbase.new
    award = fb.insert
    award.what = 'award'
    award.repository = 12_345
    responses = [
      {
        full_name: 'yegor256/test', description: 'first', stargazers_count: 1,
        forks_count: 2, language: 'Ruby', open_issues_count: 3, updated_at: '2024-01-01T00:00:00Z'
      },
      {
        full_name: 'yegor256/test', description: 'second', stargazers_count: 9,
        forks_count: 8, language: 'Crystal', open_issues_count: 7, updated_at: '2024-01-02T00:00:00Z'
      }
    ]
    client = Object.new
    client.define_singleton_method(:repository) { |_id| responses.shift }
    orig = Fbe.method(:octo)
    Fbe.define_singleton_method(:octo) { client }
    begin
      run_judge(fb)
      run_judge(fb)
    ensure
      Fbe.define_singleton_method(:octo, orig)
    end
    details = fb.query('(eq what "repo-details")').each.to_a
    assert_equal(1, details.length, fb.to_json)
    assert_equal('second', details.first.description, fb.to_json)
    assert_equal(9, details.first.stars, fb.to_json)
  end

  private

  def run_judge(fb)
    $fb = fb
    $global = {}
    $local = {}
    $judge = 'copy-repo-names'
    $options = Judges::Options.new('repositories' => 'foo/foo')
    $loog = Loog::NULL
    load(File.join(__dir__, '../../judges/copy-repo-names/copy-repo-names.rb'))
  end
end
