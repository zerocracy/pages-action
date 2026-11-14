# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

def numeric?(val)
  val.is_a?(Numeric) && val.finite?
end

def ratio(num, den)
  return unless numeric?(num) && numeric?(den) && !den.zero?
  res = (num.to_r / den.to_r).to_f
  res if res.finite?
end

common =
  "
  (eq what 'earned-value')
  (exists when)
  (exists ev)
  "

def apply(common, denom, target)
  Fbe.fb.query(
    "
    (and
      #{common}
      (exists #{denom})
      (not (eq #{denom} 0))
      (absent #{target}))
    "
  ).each do |f|
    val = ratio(f.ev, f[denom].first)
    yield(f, val) unless val.nil?
  end
end

apply(common, 'ac', 'n_cpi') { |f, v| f.n_cpi = v }
apply(common, 'pv', 'n_spi') { |f, v| f.n_spi = v }
