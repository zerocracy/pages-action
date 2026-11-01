# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'
require 'fbe/overwrite'

def fits?(fact, name)
  return true if name == 'composite'
  return false unless name.match?(/^[a-z]+_[a-z]+.*$/)
  return false if name.start_with?('n_')
  return false if name.start_with?('some_') && !fact["average_#{name.delete_prefix('some_')}"].nil?
  true
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
      fresh["n_#{prop}"] = ((value(f, prop) - s) / s).to_f
    end
    next if fresh.empty?
    Fbe.overwrite(f, fresh)
  end
end
