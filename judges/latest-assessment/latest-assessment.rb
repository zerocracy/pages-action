# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'
require 'time'

Fbe.fb.txn do |fb|
  today = $options.today.nil? ? Time.now : Time.parse($options.today)
  assessments =
    fb.query('(and (eq what "assessment") (exists text) (exists when))').each.to_a.select do |a|
      a['when'].min <= today
    end
  fb.query('(eq what "latest-assessment")').delete!
  next if assessments.empty?
  latest = assessments.max_by { |assessment| assessment['when'].min }
  f = fb.insert
  f.what = 'latest-assessment'
  f.text = latest.text
  f.when = latest['when'].min
  f.total = assessments.size
end
