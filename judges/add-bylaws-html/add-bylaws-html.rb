# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/award'
require 'fbe/fb'
require 'redcarpet'

props = {}
Fbe.fb.query('(and (eq what "pmp") (eq area "hr"))').each do |f|
  f.all_properties.each do |prop|
    props[prop] = f[prop].first unless props.key?(prop)
  end
end
htmls = []
props.each do |prop, q|
  next unless q.is_a?(String)
  next unless q.start_with?('(award')
  md =
    begin
      Fbe::Award.new(q).bylaw.markdown
    rescue Fbe::Error => e
      $loog.warn("The bylaw '#{prop}' can't be rendered: #{e.message}")
      next
    end
  htmls << Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(escape_html: true), no_intra_emphasis: true).render(md)
end
return if htmls.empty?
Fbe.fb.query('(eq what "bylaws")').delete!
s = Fbe.fb.insert
s.what = 'bylaws'
s.html = htmls.join
