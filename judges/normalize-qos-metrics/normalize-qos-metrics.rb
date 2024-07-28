# frozen_string_literal: true

# MIT License
#
# Copyright (c) 2024 Zerocracy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'fbe/fb'

facts = Fbe.fb.query('(eq what "quality-of-service")').each.to_a

facts.sort! { |a, b| a.when <=> b.when }
return if facts.empty?

start = {}
first = facts.first
first.all_properties.each do |prop|
  next unless prop.match?(/^[a-z]+_[a-z]+.*$/)
  next if prop.start_with?('n_')
  start[prop] = first[prop][0]
end

facts.drop(1).each do |f|
  f.all_properties.each do |prop|
    next unless prop.match?(/^[a-z]+_[a-z]+.*$/)
    next if prop.start_with?('n_')
    v = f[prop][0]
    start[prop] = v if start[prop].nil?
  end
end

facts.each do |f|
  f.all_properties.each do |prop|
    next unless prop.match?(/^[a-z]+_[a-z]+.*$/)
    next if prop.start_with?('n_')
    v = f[prop][0]
    s = start[prop]
    diff = v - s
    diff /= start[prop] unless start[prop].zero?
    f.send("n_#{prop}=", diff)
  end
end
