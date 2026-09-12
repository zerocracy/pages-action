# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'
require 'fbe/octo'

ids = Fbe.fb.query('(exists repository)').each.map(&:repository).uniq
return if ids.empty?

repos =
  ids.each_with_object({}) do |id, h|
    h[id] = Fbe.octo.repository(id)
  rescue Fbe::OffQuota
    break h
  rescue Octokit::Error, Faraday::Error
    next
  end

repos.each do |id, json|
  Fbe.fb.query("(and (eq what \"repo-details\") (eq repository #{id.inspect}))").delete!
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
