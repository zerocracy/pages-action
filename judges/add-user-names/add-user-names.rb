# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/octo'

Fbe.fb.query(
  '(and
    (or (eq where "github") (not (exists where)))
    (exists who)
    (not (exists who_name)) (not (exists who_noname)))'
).each do |f|
  n = Fbe.octo.user_name_by_id(f.who)
  f.who_name = n
  $loog.debug("User ##{f.who} is actually @#{f.who_name}")
rescue Octokit::NotFound => e
  f.who_noname = 'not found'
  $loog.warn("THe user ##{f.who} is absent in GitHub: #{e.message}")
end
