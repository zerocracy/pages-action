# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'
require 'fbe/octo'

known = Fbe.fb.query('(eq what "repo-details")').each.filter_map(&:repository).to_a
ids = Fbe.fb.query('(exists repository)').each.map(&:repository).uniq - known
return if ids.empty?

repos =
  ids.filter_map do |id|
    [id, Fbe.octo.repository(id)]
  rescue Octokit::NotFound, Octokit::Deprecated => e
    $loog.warn("GitHub repository ##{id} is absent: #{e.class}: #{e.message}")
    nil
  rescue Octokit::Unauthorized, Octokit::Forbidden => e
    $loog.warn("GitHub repository ##{id} is not accessible: #{e.class}: #{e.message}")
    nil
  end.to_h

repos.each do |id, json|
  d = Fbe.fb.insert
  d.what = 'repo-details'
  d.where = 'github'
  d.repository = id
  d.repository_name = json[:full_name]
  d.description = json[:description].to_s
  d.stars = json[:stargazers_count]
  d.forks = json[:forks_count]
  d.language = json[:language].to_s
  d.open_issues = json[:open_issues_count]
  d.updated_at = json[:updated_at]
end
