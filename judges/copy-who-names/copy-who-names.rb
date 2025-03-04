# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

Fbe.fb.query(
  '(and
    (exists who)
    (not (exists who_name))
    (join "name_found<=name"
      (and
        (eq what "who-has-name")
        (eq where $where)
        (eq who $who)))
    (exists name_found))'
).each.to_a.each do |f|
  f.who_name = f.name_found
end
