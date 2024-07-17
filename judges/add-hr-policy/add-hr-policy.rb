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
require 'fbe/award'
require 'redcarpet'

f = Fbe.fb.query('(and (eq what "pmp") (eq area "hr"))').each.to_a.first
htmls = []
par = 1
f&.all_properties&.each do |prop|
  q = f[prop].first
  next unless q.is_a?(String)
  next unless q.start_with?('(award ')
  md = Fbe::Award.new(q).policy.markdown
  md = "§#{par} #{md}"
  htmls << Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(md)
  par += 1
end
s = Fbe.fb.insert
s.what = 'hr-policy'
s.html = "<div>#{htmls.join}</div>"
