# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

# Test that the rich XML is printed the same way as the published dumps.
class TestEntryRich < Minitest::Test
  def test_prints_the_rich_xml_with_the_same_options
    block = File.read(File.join(__dir__, '..', 'entry.sh'))[
      /^\$\{JUDGES\} "\$\{gopts\[@\]\}" print \\\n(?:.*\n)*?.*name\}\.rich\.xml"\n/
    ]
    refute_nil(block, 'No rich.xml printing found in entry.sh')
    ['--columns "${INPUT_COLUMNS}"', '--highlighted "${INPUT_HIGHLIGHTED}"', '--hidden "${INPUT_HIDDEN}"'].each do |o|
      assert_includes(block, o, "the rich XML is printed without #{o}")
    end
  end
end
