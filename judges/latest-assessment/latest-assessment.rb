# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

return unless Fbe.fb.query('(eq what "latest-assessment")').each.to_a.empty?

assessments = Fbe.fb.query('(and (eq what "assessment") (exists text) (exists when))').each.to_a
return if assessments.empty?

latest = assessments.max_by(&:when)

f = Fbe.fb.insert
f.what = 'latest-assessment'
f.text = latest.text
f.when = latest.when
f.total = assessments.size
