# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'
require 'fbe/octo'

facts = Fbe.fb.query('(and (exists repository) (not (exists repository_name)))').each.to_a
return if facts.empty?

names = facts.map(&:repository).uniq.to_h { |id| [id, Fbe.octo.repo_name_by_id(id)] }

facts.each do |f|
  n = names[f.repository]
  next if n.nil?
  f.repository_name = n
end
