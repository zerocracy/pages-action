# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'open3'
require 'tmpdir'
require_relative 'test__helper'

class TestEntryTitle < Minitest::Test
  def test_titles_every_format_with_the_factbase_name
    calls = execute_print_loop(name: 'example')
    assert_equal(4, calls.size, calls)
    %w[yaml xml json html].each do |f|
      call = calls.find { |args| args.each_cons(2).include?(['--format', f]) }
      refute_nil(call, "No '#{f}' dump is printed")
      pair = call.each_cons(2).find { |opt, _| opt == '--title' }
      assert_equal(['--title', 'example'], pair, "the '#{f}' dump is printed without the factbase name as its title")
    end
  end

  def test_titles_with_custom_factbase_name
    calls = execute_print_loop(name: 'custom-fb')
    assert_equal(4, calls.size, calls)
    %w[yaml xml json html].each do |f|
      call = calls.find { |args| args.each_cons(2).include?(['--format', f]) }
      refute_nil(call, "No '#{f}' dump is printed")
      pair = call.each_cons(2).find { |opt, _| opt == '--title' }
      assert_equal(['--title', 'custom-fb'], pair, "the '#{f}' dump is printed without the custom name as its title")
    end
  end

  def test_passes_columns_options_to_every_format
    calls = execute_print_loop(columns: 'alpha,beta,gamma')
    %w[yaml xml json html].each do |f|
      call = calls.find { |args| args.each_cons(2).include?(['--format', f]) }
      refute_nil(call, "No '#{f}' dump is printed")
      pair = call.each_cons(2).find { |opt, _| opt == '--columns' }
      assert_equal(['--columns', 'alpha,beta,gamma'], pair, "the '#{f}' dump is printed without correct columns")
    end
  end

  def test_passes_highlighted_and_hidden_options
    calls = execute_print_loop(highlighted: 'recent', hidden: 'secret')
    %w[yaml xml json html].each do |f|
      call = calls.find { |args| args.each_cons(2).include?(['--format', f]) }
      refute_nil(call, "No '#{f}' dump is printed")
      highlighted = call.each_cons(2).find { |opt, _| opt == '--highlighted' }
      assert_equal(['--highlighted', 'recent'], highlighted)
      hidden = call.each_cons(2).find { |opt, _| opt == '--hidden' }
      assert_equal(['--hidden', 'secret'], hidden)
    end
  end

  private

  def execute_print_loop(name: 'example', columns: 'what,when,who', highlighted: 'stale', hidden: '_id')
    block = File.read(File.join(__dir__, '..', 'entry.sh'))[/^for f in yaml xml json html; do\n.*?^ *done$/m]
    refute_nil(block, 'No print loop found in entry.sh')
    Dir.mktmpdir do |dir|
      script = "#!/usr/bin/env bash\nprintf '%s\\037' \"$@\" >> \"#{dir}/log\"\nprintf '\\n' >> \"#{dir}/log\"\n"
      %w[run_judges judges].each do |cmd|
        path = File.join(dir, cmd)
        File.write(path, script)
        File.chmod(0o755, path)
      end
      _, stderr, status = Open3.capture3(
        {
          'PATH' => "#{dir}:#{ENV.fetch('PATH')}",
          'INPUT_COLUMNS' => columns,
          'INPUT_HIGHLIGHTED' => highlighted,
          'INPUT_HIDDEN' => hidden,
          'INPUT_FACTBASE' => "#{name}.fb",
          'staging' => dir,
          'name' => name
        },
        'bash', '-e', '-c', block
      )
      assert_predicate(status, :success?, stderr)
      File.readlines(File.join(dir, 'log'), chomp: true).map { |line| line.split("\u001F") }
    end
  end
end
