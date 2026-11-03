# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'
require 'fbe/overwrite'

common =
  "
  (eq what 'earned-value')
  (exists when)
  (exists ev)
  "

Fbe.fb.query(
  "
  (and
    #{common}
    (exists ac)
    (not (eq ac 0)))
  "
).each.to_a.each do |f|
  Fbe.overwrite(f, 'n_cpi', f.ev.to_f / f.ac, fb: Fbe.fb)
end

Fbe.fb.query(
  "
  (and
    #{common}
    (exists pv)
    (not (eq pv 0)))
  "
).each.to_a.each do |f|
  Fbe.overwrite(f, 'n_spi', f.ev.to_f / f.pv, fb: Fbe.fb)
end
