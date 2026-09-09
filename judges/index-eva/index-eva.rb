# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

common =
  "
  (eq what 'earned-value')
  (exists when)
  (exists start)
  (exists ev)
  "

Fbe.fb.query(
  "
  (and
    #{common}
    (exists ac)
    (not (eq ac 0))
    (absent n_cpi))
  "
).each do |f|
  f.n_cpi = f.ev / f.ac
end

Fbe.fb.query(
  "
  (and
    #{common}
    (exists pv)
    (not (eq pv 0))
    (absent n_spi))
  "
).each do |f|
  f.n_spi = f.ev / f.pv
end
