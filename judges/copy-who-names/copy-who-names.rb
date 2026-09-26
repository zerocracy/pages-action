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
  ).each.to_a.sort_by do |f|
    stamp = f['when']&.first
    [stamp.nil? ? 0 : 1, stamp || Time.at(0), f.name]
  end.to_h { |f| [f.who, f.name] }

Fbe.fb.query(
  '(and
    (not (eq what "who-has-name"))
    (exists who)
    (not (exists who_name)))'
).each do |f|
  n = names[f.who]
  next if n.nil?
  f.who_name = n
end
