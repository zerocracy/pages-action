# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'
require 'fbe/overwrite'

def finite?(value)
  value.is_a?(Numeric) && (!value.is_a?(Float) || value.finite?)
end

def fits?(fact, name)
  return false unless name == 'composite' || name.match?(/^[a-z]+_[a-z]+.*$/)
  return false if name.start_with?('n_')
  return false if name.start_with?('some_') && !fact["average_#{name.delete_prefix('some_')}"].nil?
  vv = fact[name]
  !vv.nil? && !vv.empty? && vv.all? { |v| finite?(v) }
end

def value(fact, name)
  vv = fact[name]
  return vv.first.to_r unless name.start_with?('some_')
  vv.sum(&:to_r) / vv.size
end

%w[quantity-of-deliverables quality-of-service].each do |qo|
  facts = Fbe.fb.query("(and (eq what '#{qo}') (exists when))").each.to_a
  facts.sort_by! { |f| f['when'].min }
  next if facts.empty?
  start = {}
  first = facts.first
  first.all_properties.each do |prop|
    next unless fits?(first, prop)
    start[prop] = value(first, prop)
  end
  facts.drop(1).each do |f|
    f.all_properties.each do |prop|
      next unless fits?(f, prop)
      start[prop] = value(f, prop) if start[prop].nil?
    end
  end
  facts.each do |f|
    fresh = {}
    f.all_properties.each do |prop|
      next unless fits?(f, prop)
      next if start[prop].zero?
      s = start[prop]
      ratio = ((value(f, prop) - s) / s).to_f
      next unless ratio.finite?
      fresh["n_#{prop}"] = ratio
    end
    next if fresh.empty?
    Fbe.overwrite(f, fresh)
  end
end
