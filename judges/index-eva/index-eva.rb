# frozen_string_literal: true

# MIT License
#
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

Fbe.fb.query("
  (and
    (eq what 'earned-value-prev')
    (exists when)
    (exists start)
    (exists ac)
    (not (eq ac 0))
    (exists pv)
    (not (eq pv 0))
    (exists ev))
  ").each do |f|
  f.n_cpi = f.ev / f.ac
  f.n_spi = f.ev / f.pv
end
