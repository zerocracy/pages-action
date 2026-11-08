# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class TestEntryFunctions < Minitest::Test
  def test_defines_no_function_that_shadows_the_judges_command
    functions = File.read(File.join(__dir__, '..', 'entry.sh')).scan(/^([a-z_]+)\(\) \{$/).flatten
    refute_empty(functions, 'No functions found in entry.sh')
    refute_includes(functions, 'judges', 'A "judges" function calls itself when JUDGES is "judges"')
  end
end
