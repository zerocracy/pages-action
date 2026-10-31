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
  end

  def test_keeps_stored_details_when_github_fails
    [Fbe::OffQuota.new('off-quota'), Faraday::ConnectionFailed.new('no network')].each do |error|
      fb = Factbase.new
      (1..2).each do |id|
        award = fb.insert
        award.what = 'award'
        award.repository = id
      end
      old = fb.insert
      old.what = 'repo-details'
      old.repository = 2
      old.stars = 7
      client = Object.new
      client.define_singleton_method(:repository) do |id|
        raise(error) if id == 2
        {
          full_name: 'yegor256/one', description: 'one', stargazers_count: 1,
          forks_count: 1, language: 'Ruby', open_issues_count: 1, updated_at: '2024-01-01T00:00:00Z'
        }
      end
      orig = Fbe.method(:octo)
      Fbe.define_singleton_method(:octo) { client }
      begin
        load_it('copy-repo-names', fb)
      ensure
        Fbe.define_singleton_method(:octo, orig)
      end
      assert_equal(
        ['yegor256/one'],
        fb.query('(and (eq what "repo-details") (eq repository 1))').each.map(&:repository_name),
        error
      )
      assert_equal([7], fb.query('(and (eq what "repo-details") (eq repository 2))').each.map(&:stars), error)
    end
  end
end
