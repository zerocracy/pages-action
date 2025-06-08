# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

def fits?(name)
  return true if name == 'composite'
  return false unless name.match?(/^[a-z]+_[a-z]+.*$/)
  return false if name.start_with?('n_')
  true
end

%w[quantity-of-deliverables quality-of-service].each do |qo|
  facts = Fbe.fb.query("(eq what '#{qo}')").each.to_a

  facts.sort_by!(&:when)
  next if facts.empty?

  start = {}
  first = facts.first
  first.all_properties.each do |prop|
    next unless fits?(prop)
    start[prop] = first[prop][0].to_f
  end

  facts.drop(1).each do |f|
    f.all_properties.each do |prop|
      next unless fits?(prop)
      v = f[prop][0].to_f
      start[prop] = v if start[prop].nil?
    end
  end

  facts.each do |f|
    f.all_properties.each do |prop|
      next unless fits?(prop)
      v = f[prop][0]
      s = start[prop]
      diff = v - s
      diff /= start[prop] unless start[prop].zero?
      f.send(:"n_#{prop}=", diff)
    end
  end
end
