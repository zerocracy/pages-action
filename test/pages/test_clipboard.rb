# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'open3'
require_relative '../test__helper'

class TestClipboard < Minitest::Test
  def test_removes_the_checkmark_once_it_has_faded
    assert_equal('shown faded removed', clicked('Promise.resolve()'), 'the checkmark stays in the page after it faded')
  end

  def test_shows_no_checkmark_when_the_copy_fails
    assert_equal('alert: Failed to copy to clipboard!', clicked('Promise.reject(new Error())'))
  end

  private

  def clicked(result)
    script = [
      'const log = [];',
      'let click;',
      'const node = () => ({',
      '  click: (f) => { click = f; },',
      "  attr: () => 'text',",
      "  after: () => log.push('shown'),",
      '  delay() { return this; },',
      "  fadeOut(done) { log.push('faded'); if (done) { done(); } return this; },",
      "  remove: () => log.push('removed')",
      '});',
      "global.$ = (arg) => (typeof arg === 'function' ? arg() : node());",
      'global.alert = (m) => log.push(`alert: ${m}`);',
      "const clipboard = { writeText: () => #{result} };",
      "Object.defineProperty(globalThis, 'navigator', { value: { clipboard } });",
      'global.window = { isSecureContext: true };',
      File.read(File.join(__dir__, '../../js/clipboard.js')),
      'click({ currentTarget: {} });',
      "setTimeout(() => process.stdout.write(log.join(' ')), 10);"
    ].join("\n")
    out, status = Open3.capture2('node', '-e', script)
    assert_predicate(status, :success?, out)
    out
  end
end
