# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'nokogiri'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestBadge < Minitest::Test
  def test_validate_svg
    WebMock.enable_net_connect!
    f = File.join(__dir__, '../../target/html/simple-badge.svg')
    skip unless File.exist?(f)
    svg = File.read(f)
    xml =
      begin
        Nokogiri::XML.parse(svg) do |c|
          c.norecover
          c.strict
        end
      rescue StandardError => e
        raise "#{svg}\n\n#{e}"
      end
    assert_empty(xml.errors, svg)
    refute_empty(xml.xpath('/svg'), svg)
  end
end
