# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require 'faraday/http_cache'
require 'fbe/middleware/sqlite_store'
require 'tmpdir'
require 'webmock/minitest'

class TestHttpCache < Minitest::Test
  def test_reuses_authenticated_responses_from_sqlite
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'http.sqlite')
      request = stub_request(:get, 'https://api.github.com/repos/acme/pages')
        .with(headers: { 'Authorization' => 'token example' })
        .to_return(body: 'repository', headers: { 'Cache-Control' => 'private, max-age=3600' })
      assert_equal('repository', cached_client(path).get('/repos/acme/pages').body)
      response = cached_client(path).get('/repos/acme/pages')
      assert_equal('repository', response.body)
      assert_includes(response.env[:http_cache_trace], :fresh)
      assert_requested(request, times: 1)
    end
  end

  def test_revalidates_with_etag_and_keeps_the_cached_body
    Dir.mktmpdir do |dir|
      client = cached_client(File.join(dir, 'http.sqlite'))
      stub_request(:get, 'https://api.github.com/repos/acme/pages')
        .to_return(body: 'repository', headers: { 'Cache-Control' => 'private, no-cache', 'ETag' => '"v1"' })
      assert_equal('repository', client.get('/repos/acme/pages').body)
      validation = stub_request(:get, 'https://api.github.com/repos/acme/pages')
        .with(headers: { 'If-None-Match' => '"v1"' })
        .to_return(status: 304, headers: { 'Cache-Control' => 'private, max-age=3600' })
      response = client.get('/repos/acme/pages')
      assert_equal(200, response.status)
      assert_equal('repository', response.body)
      assert_includes(response.env[:http_cache_trace], :valid)
      assert_equal('repository', client.get('/repos/acme/pages').body)
      assert_requested(validation, times: 1)
    end
  end

  def test_does_not_store_no_store_responses
    Dir.mktmpdir do |dir|
      client = cached_client(File.join(dir, 'http.sqlite'))
      request = stub_request(:get, 'https://api.github.com/repos/acme/pages')
        .to_return(body: 'first', headers: { 'Cache-Control' => 'no-store' })
        .then.to_return(body: 'second', headers: { 'Cache-Control' => 'no-store' })
      assert_equal('first', client.get('/repos/acme/pages').body)
      assert_equal('second', client.get('/repos/acme/pages').body)
      assert_requested(request, times: 2)
    end
  end

  def test_does_not_share_authenticated_responses
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'http.sqlite')
      stub_request(:get, 'https://api.github.com/repos/acme/pages')
        .with(headers: { 'Authorization' => 'token example' })
        .to_return(body: 'first user', headers: { 'Cache-Control' => 'max-age=3600' })
      request = stub_request(:get, 'https://api.github.com/repos/acme/pages')
        .with(headers: { 'Authorization' => 'token another' })
        .to_return(body: 'second user', headers: { 'Cache-Control' => 'max-age=3600' })
      assert_equal('first user', cached_client(path, shared: true).get('/repos/acme/pages').body)
      assert_equal('second user', cached_client(path, shared: true, token: 'another').get('/repos/acme/pages').body)
      assert_requested(request, times: 1)
    end
  end

  private

  def cached_client(path, shared: false, token: 'example')
    Faraday.new('https://api.github.com', headers: { 'Authorization' => "token #{token}" }) do |builder|
      builder.use(
        Faraday::HttpCache,
        store: Fbe::Middleware::SqliteStore.new(path, 'test'), serializer: JSON, shared_cache: shared
      )
      builder.adapter(Faraday.default_adapter)
    end
  end
end
