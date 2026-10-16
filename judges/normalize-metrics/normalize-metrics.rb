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
  return vv.first.to_f unless name.start_with?('some_')
  vv.sum(&:to_f) / vv.size
end

def rebuild(fact, props)
  id = fact['_id'].first
  Fbe.fb.txn do |fbt|
    fbt.query("(eq _id #{id})").delete!
    n = fbt.insert
    f = n
    while f.instance_variable_defined?(:@fact) || f.instance_variable_defined?(:@origin)
      f = f.instance_variable_get(f.instance_variable_defined?(:@fact) ? :@fact : :@origin)
    end
    map = f.instance_variable_get(:@map)
    %w[_id _time _version _job].each { |k| map.delete(k) if props.key?(k) }
    props.each do |k, vv|
      vv.each { |v| n.public_send(:"#{k}=", v) }
    end
  end
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
      fresh["n_#{prop}"] = (value(f, prop) - s) / s
    end
    stale = f.all_properties.map(&:to_s).select { |p| p.start_with?('n_') && !fresh.key?(p) }
    if stale.empty?
      Fbe.overwrite(f, fresh) unless fresh.empty?
    else
      props = f.all_properties.to_h { |k| [k.to_s, f[k]] }
      stale.each { |p| props.delete(p) }
      fresh.each { |k, v| props[k] = [v] }
      rebuild(f, props)
    end
  end
end
