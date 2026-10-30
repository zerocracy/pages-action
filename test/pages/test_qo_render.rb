# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'json'
require 'open3'
require_relative '../test__helper'

class TestQoRender < Minitest::Test
  def test_uses_the_full_date_for_the_hovered_point
    data = { labels: ['1/2', '2/3'], fullDates: ['2 JAN 2026', '3 FEB 2026'] }
    assert_equal('3 FEB 2026', title(data, { dataIndex: 1, label: '2/3' }))
  end

  def test_falls_back_to_the_axis_label_without_full_dates
    assert_equal('2/3', title({ labels: ['2/3'] }, { dataIndex: 0, label: '2/3' }))
  end

  private

  def title(data, item)
    script = [
      "global.document = { getElementById: (id) => id === 'chart' ? { style: {} } : null };",
      'let configuration;',
      'global.Chart = class { constructor(_context, config) { configuration = config; } };',
      File.read(File.join(__dir__, '../../js/qo-section.js')),
      "qo_render('chart', #{data.to_json});",
      "const value = configuration.options.plugins.tooltip.callbacks.title([#{item.to_json}]);",
      'process.stdout.write(JSON.stringify(value));'
    ].join("\n")
    out, status = Open3.capture2('node', '-e', script)
    assert_predicate(status, :success?, out)
    JSON.parse(out)
  end
end
