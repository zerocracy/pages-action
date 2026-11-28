# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'json'
require 'open3'
require_relative '../test__helper'

class TestClipboard < Minitest::Test
  def test_removes_the_checkmark_once_it_has_faded
    markdown = '[![Vitals](https://example.com/badge.svg)](https://example.com/vitals.html)'
    result = clicked(markdown, '(text) => { copied = text; return Promise.resolve(); }')
    assert_equal(markdown, result['copied'], 'the clicked badge Markdown must reach the clipboard')
    assert_equal(%w[shown faded removed], result['log'], 'the checkmark stays in the page after it faded')
  end

  def test_shows_no_checkmark_when_the_copy_fails
    assert_equal(
      ['alert: Failed to copy to clipboard!'],
      clicked('text', '() => Promise.reject(new Error())')['log'],
      'a failed copy must alert and show no checkmark'
    )
  end

  private

  def clicked(markdown, write)
    script = [
      "const markdown = #{markdown.to_json};",
      'const log = [];',
      'let click;',
      'let copied;',
      'const node = () => ({',
      '  click: (f) => { click = f; },',
      "  attr: (name) => name === 'data-text' ? markdown : 'wrong attribute',",
      "  after: () => log.push('shown'),",
      '  delay() { return this; },',
      "  fadeOut(done) { log.push('faded'); if (done) { done(); } return this; },",
      "  remove: () => log.push('removed')",
      '});',
      "global.$ = (arg) => (typeof arg === 'function' ? arg() : node());",
      'global.alert = (m) => log.push(`alert: ${m}`);',
      "const clipboard = { writeText: #{write} };",
      "Object.defineProperty(globalThis, 'navigator', { value: { clipboard } });",
      'global.window = { isSecureContext: true };',
      File.read(File.join(__dir__, '../../js/clipboard.js')),
      'click({ currentTarget: {} });',
      'setTimeout(() => process.stdout.write(JSON.stringify({ copied, log })), 10);'
    ].join("\n")
    out, status = Open3.capture2('node', '-e', script)
    assert_predicate(status, :success?, out)
    JSON.parse(out)
  end
end
