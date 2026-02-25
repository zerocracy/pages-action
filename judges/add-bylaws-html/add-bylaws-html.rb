# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'
require 'fbe/award'
require 'redcarpet'

return unless Fbe.fb.query('(eq what "bylaws")').each.to_a.empty?

f = Fbe.fb.query('(and (eq what "pmp") (eq area "hr"))').each.to_a.first
htmls = []
par = 1
f&.all_properties&.each do |prop|
  q = f[prop].first
  next unless q.is_a?(String)
  next unless q.start_with?('(award')
  md = Fbe::Award.new(q).bylaw.markdown
  htmls << Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(md)
  par += 1
end
s = Fbe.fb.insert
s.what = 'bylaws'
s.html = htmls.join unless htmls.empty?
