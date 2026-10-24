# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'open3'
require 'tmpdir'
require_relative 'test__helper'

class TestEntryTitle < Minitest::Test
  def test_titles_every_format_with_the_factbase_name
    block = File.read(File.join(__dir__, '..', 'entry.sh'))[/^for f in yaml xml json html; do\n.*?^ *done$/m]
    refute_nil(block, 'No print loop found in entry.sh')
    Dir.mktmpdir do |dir|
      File.write(
        File.join(dir, 'judges'),
        "#!/usr/bin/env bash\nprintf '%s\\037' \"$@\" >> \"#{dir}/log\"\nprintf '\\n' >> \"#{dir}/log\"\n"
      )
      File.chmod(0o755, File.join(dir, 'judges'))
      _, stderr, status = Open3.capture3(
        {
          'PATH' => "#{dir}:#{ENV.fetch('PATH')}",
          'INPUT_COLUMNS' => 'what,when,who',
          'INPUT_HIGHLIGHTED' => 'stale',
          'INPUT_HIDDEN' => '_id',
          'INPUT_FACTBASE' => 'example.fb',
          'staging' => dir,
          'name' => 'example'
        },
        'bash', '-e', '-c', block
      )
      assert_predicate(status, :success?, stderr)
      calls = File.readlines(File.join(dir, 'log'), chomp: true).map { |line| line.split("\u001F") }
      assert_equal(4, calls.size, calls)
      %w[yaml xml json html].each do |f|
        call = calls.find { |args| args.each_cons(2).include?(['--format', f]) }
        refute_nil(call, "No '#{f}' dump is printed")
        pair = call.each_cons(2).find { |opt, _| opt == '--title' }
        assert_equal(['--title', 'example'], pair, "the '#{f}' dump is printed without the factbase name as its title")
      end
    end
  end
end
