# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

Fbe.fb.txn do |fb|
  assessments = fb.query('(and (eq what "assessment") (exists text) (exists when))').each.to_a
  next if assessments.empty?
  latest = assessments.max_by(&:when)
  fb.query('(eq what "latest-assessment")').delete!
  f = fb.insert
  f.what = 'latest-assessment'
  f.text = latest.text
  f.when = latest.when
  f.total = assessments.size
end
