# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/award'
require 'fbe/fb'
require 'redcarpet'

f = Fbe.fb.query('(and (eq what "pmp") (eq area "hr"))').each.to_a.first
htmls = []
par = 1
f&.all_properties&.each do |prop|
  q = f[prop].first
  next unless q.is_a?(String)
  next unless q.start_with?('(award')
  md = Fbe::Award.new(q).bylaw.markdown
  htmls << Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(escape_html: true)).render(md)
  par += 1
end
Fbe.fb.query('(eq what "bylaws")').delete!
return if htmls.empty?
s = Fbe.fb.insert
s.what = 'bylaws'
s.html = htmls.join
