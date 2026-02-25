# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

names =
  Fbe.fb.query(
    '(and
      (eq what "who-has-name")
      (exists who)
      (exists name))'
  ).each.to_a.to_h { |f| [f.who, f.name] }

Fbe.fb.query('(and (exists who) (not (exists who_name)))').each do |f|
  n = names[f.who]
  next if n.nil?
  f.who_name = n
end
