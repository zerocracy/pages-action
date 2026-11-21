# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'cgi'
require 'nokogiri'

page = Nokogiri::HTML(File.read(ARGV.fetch(0)))
description = page.at_css('meta[name="description"]')['content']
url = page.at_css('meta[property="og:url"]')&.[]('content')
summary = "<p>#{CGI.escapeHTML(description)}</p>\n"
summary += "<p><a href=\"#{CGI.escapeHTML(url)}\">View published report</a></p>\n" unless url.nil? || url.empty?
File.open(ARGV.fetch(1), 'a') { |file| file.write(summary) }
