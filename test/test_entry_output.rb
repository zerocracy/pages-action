# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'English'
require 'tmpdir'
require_relative 'test__helper'

class TestEntryOutput < Minitest::Test
  def test_creates_an_output_directory_that_starts_with_a_hyphen
    script = File.read(File.join(__dir__, '..', 'entry.sh'))[
      /^if \[ -z "\$\{INPUT_OUTPUT\}" \]; then\n(?:.*\n)*?staging=.*\n/
    ]
    refute_nil(script, 'No output directory setup found in entry.sh')
    Dir.mktmpdir do |dir|
      out = IO.popen(
        { 'INPUT_OUTPUT' => '-generated-pages' },
        ['bash', '-e', '-c', "#{script}\necho \"${staging}\"; test -d \"${INPUT_OUTPUT}\""],
        chdir: dir, err: %i[child out], &:read
      )
      assert_predicate($CHILD_STATUS, :success?, out)
      assert_path_exists(File.join(dir, '-generated-pages'), out)
      assert_includes(out, '-generated-pages/.pages-action.', out)
    end
  end
end
