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
      load_it('copy-repo-names', fb)
      load_it('copy-repo-names', fb)
    ensure
      Fbe.define_singleton_method(:octo, orig)
    end
    details = fb.query('(eq what "repo-details")').each.to_a
    assert_equal(1, details.length, fb.to_json)
    assert_equal('second', details.first.description, fb.to_json)
    assert_equal(9, details.first.stars, fb.to_json)
    assert_equal(8, details.first.forks, fb.to_json)
    assert_equal('Crystal', details.first.language, fb.to_json)
    assert_equal(7, details.first.open_issues, fb.to_json)
    assert_equal('2024-01-02T00:00:00Z', details.first.updated_at, fb.to_json)
  end

  def test_keeps_details_fetched_before_quota_runs_out
    fb = Factbase.new
    [111, 222].each do |id|
      award = fb.insert
      award.what = 'award'
      award.repository = id
    end
    client = Object.new
    client.define_singleton_method(:repository) do |id|
      raise(Fbe::OffQuota, 'no quota') if id == 222
      {
        full_name: 'yegor256/first', description: 'first', stargazers_count: 5,
        forks_count: 1, language: 'Ruby', open_issues_count: 0, updated_at: '2024-01-01T00:00:00Z'
      }
    end
    orig = Fbe.method(:octo)
    Fbe.define_singleton_method(:octo) { client }
    begin
      load_it('copy-repo-names', fb)
    ensure
      Fbe.define_singleton_method(:octo, orig)
    end
    details = fb.query('(eq what "repo-details")').each.to_a
    assert_equal([111], details.map(&:repository), fb.to_json)
    assert_equal('yegor256/first', details.first.repository_name, fb.to_json)
  end

  def test_records_archived_as_a_string
    fb = Factbase.new
    award = fb.insert
    award.what = 'award'
    award.repository = 12_345
    client = Object.new
    client.define_singleton_method(:repository) do |_id|
      {
        full_name: 'yegor256/test', description: 'd', archived: true,
        stargazers_count: 1, forks_count: 2, language: 'Ruby',
        open_issues_count: 3, updated_at: '2024-01-01T00:00:00Z'
      }
    end
    orig = Fbe.method(:octo)
    Fbe.define_singleton_method(:octo) { client }
    begin
      load_it('copy-repo-names', fb)
    ensure
      Fbe.define_singleton_method(:octo, orig)
    end
    details = fb.query('(eq what "repo-details")').each.to_a
    assert_equal('true', details.first.archived.to_s, fb.to_json)
  end

  def test_skips_private_repository
    fb = Factbase.new
    award = fb.insert
    award.what = 'award'
    award.repository = 777
    stale = fb.insert
    stale.what = 'repo-details'
    stale.repository = 777
    stale.repository_name = 'acme/secret-plans'
    client = Object.new
    client.define_singleton_method(:repository) do |_id|
      {
        full_name: 'acme/secret-plans', description: 'Internal payroll engine', private: true,
        stargazers_count: 0, forks_count: 0, language: 'Ruby', open_issues_count: 0,
        updated_at: '2024-01-01T00:00:00Z'
      }
    end
    orig = Fbe.method(:octo)
    Fbe.define_singleton_method(:octo) { client }
    begin
      load_it('copy-repo-names', fb)
    ensure
      Fbe.define_singleton_method(:octo, orig)
    end
    assert_empty(fb.query('(eq what "repo-details")').each.to_a, fb.to_json)
  end

  def test_warns_about_a_repository_that_fails
    fb = Factbase.new
    broken = fb.insert
    broken.what = 'award'
    broken.repository = 404_123
    ok = fb.insert
    ok.what = 'award'
    ok.repository = 12_345
    error = Octokit::NotFound.new(
      status: 404, method: 'GET', url: 'https://api.github.com/repos/404123', body: 'Not Found'
    )
    client = Object.new
    client.define_singleton_method(:repository) do |id|
      raise(error) if id == 404_123
      {
        full_name: 'yegor256/test', description: 'first', stargazers_count: 1,
        forks_count: 2, language: 'Ruby', open_issues_count: 3, updated_at: '2024-01-01T00:00:00Z'
      }
    end
    warnings = []
    logger = Object.new
    logger.define_singleton_method(:debug) { |_msg| nil }
    logger.define_singleton_method(:warn) { |msg| warnings << msg }
    orig = Fbe.method(:octo)
    Fbe.define_singleton_method(:octo) { client }
    begin
      load_it_logging('copy-repo-names', fb, logger)
    ensure
      Fbe.define_singleton_method(:octo, orig)
    end
    assert_equal(["Can't fetch repository #404123: Octokit::NotFound: #{error.message}"], warnings, fb.to_json)
    details = fb.query('(eq what "repo-details")').each.to_a
    assert_equal([12_345], details.map(&:repository), fb.to_json)
  end

  def test_warns_about_unrefreshed_repositories_off_quota
    fb = Factbase.new
    ok = fb.insert
    ok.what = 'award'
    ok.repository = 12_345
    off = fb.insert
    off.what = 'award'
    off.repository = 23_456
    client = Object.new
    client.define_singleton_method(:repository) do |id|
      raise(Fbe::OffQuota, 'off quota') if id == 23_456
      {
        full_name: 'yegor256/test', description: 'first', stargazers_count: 1,
        forks_count: 2, language: 'Ruby', open_issues_count: 3, updated_at: '2024-01-01T00:00:00Z'
      }
    end
    warnings = []
    logger = Object.new
    logger.define_singleton_method(:debug) { |_msg| nil }
    logger.define_singleton_method(:warn) { |msg| warnings << msg }
    orig = Fbe.method(:octo)
    Fbe.define_singleton_method(:octo) { client }
    begin
      load_it_logging('copy-repo-names', fb, logger)
    ensure
      Fbe.define_singleton_method(:octo, orig)
    end
    assert_equal(
      ["Can't fetch repository #23456: Fbe::OffQuota: off quota, 1 repositories left unrefreshed"],
      warnings, fb.to_json
    )
    details = fb.query('(eq what "repo-details")').each.to_a
    assert_equal([12_345], details.map(&:repository), fb.to_json)
  end

  private

  def load_it_logging(judge, fb, loog)
    $fb = fb
    $global = {}
    $local = {}
    $judge = judge
    $options = Judges::Options.new('repositories' => 'foo/foo')
    $loog = loog
    load(File.expand_path("../../judges/#{judge}/#{judge}.rb", __dir__), true)
  end
end
