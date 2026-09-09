# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

Fbe.fb.query(
  "
  (and
    (eq what 'earned-value')
    (exists when)
    (exists start)
    (exists ac)
    (not (eq ac 0))
    (exists pv)
    (not (eq pv 0))
    (exists ev)
    (absent n_cpi)
    (absent n_spi))
  "
).each do |f|
  f.n_cpi = f.ev.to_f / f.ac
  f.n_spi = f.ev.to_f / f.pv
end
