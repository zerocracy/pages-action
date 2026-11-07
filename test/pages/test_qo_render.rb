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

  def test_puts_the_legend_under_the_chart
    assert_equal('bottom', rendered({ labels: [] }, 'configuration.options.plugins.legend.position'))
  end

  def test_grows_the_canvas_with_every_row_of_the_legend
    assert_equal('10em', rendered({ labels: [] }, 'canvas.style.height'))
    assert_equal('11.5em', rendered({ labels: [], datasets: [{}] * 4 }, 'canvas.style.height'))
    assert_equal('13em', rendered({ labels: [], datasets: [{}] * 5 }, 'canvas.style.height'))
  end

  private

  def title(data, item)
    rendered(data, "configuration.options.plugins.tooltip.callbacks.title([#{item.to_json}])")
  end

  def rendered(data, expression)
    script = [
      'const canvas = { style: {}, parentNode: { style: {} } };',
      "global.document = { getElementById: (id) => id === 'chart' ? canvas : null };",
      'let configuration;',
      'global.Chart = class { constructor(_context, config) { configuration = config; } };',
      File.read(File.join(__dir__, '../../js/qo-section.js')),
      "qo_render('chart', #{{ datasets: [] }.merge(data).to_json});",
      "process.stdout.write(JSON.stringify(#{expression}));"
    ].join("\n")
    out, status = Open3.capture2('node', '-e', script)
    assert_predicate(status, :success?, out)
    JSON.parse(out)
  end
end
