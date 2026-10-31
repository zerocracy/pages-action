# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative 'test__helper'

class TestEntries < Minitest::Test
  def test_rejects_a_missing_entries_directory
    with_entries do |base|
      FileUtils.remove_entry(File.join(base, 'entries'))
      out, status = run_entries(base)
      refute_predicate(status, :success?, out)
    end
  end

  def test_propagates_a_discovery_failure
    with_entries do |base|
      write_script(base, 'bin/find', '/usr/bin/find "$@"; exit 13')
      out, status = run_entries(base, { 'PATH' => "#{base}/bin:#{ENV.fetch('PATH')}" })
      refute_predicate(status, :success?, out)
    end
  end

  def test_runs_in_a_checkout_with_quotes_and_spaces
    with_entries('entries-"quoted" ') do |base|
      write_script(base, 'entries/pass.sh', 'pwd; printf "%s\n" "$1"')
      out, status = run_entries(base)
      assert_predicate(status, :success?, out)
      log = File.read(File.join(base, 'target/entries-logs/pass.sh.txt'))
      assert_equal("#{base}/target/pass.sh\n#{base}\n", log)
    end
  end

  def test_runs_nested_entries_with_their_own_work_directories_and_logs
    with_entries do |base|
      write_script(base, 'entries/nested/pass.sh', 'pwd')
      out, status = run_entries(base)
      assert_predicate(status, :success?, out)
      log = File.read(File.join(base, 'target/entries-logs/nested/pass.sh.txt'))
      assert_equal("#{base}/target/nested/pass.sh\n", log)
      assert_equal(1, out.scan('👍🏻 pass.sh passed').size, out)
    end
  end

  def test_reports_a_nested_failure_when_a_root_entry_has_the_same_name
    with_entries do |base|
      write_script(base, 'entries/nested/pass.sh', 'echo nested-failure; exit 7')
      out, status = run_entries(base)
      refute_predicate(status, :success?, out)
      assert_includes(out, 'nested-failure')
      assert_includes(out, 'nested/pass.sh failed')
    end
  end

  def test_preserves_newlines_and_spaces_in_entry_names
    with_entries do |base|
      name = "entries/name with\nnewline.sh"
      write_script(base, name, 'echo unusual-name')
      out, status = run_entries(base)
      assert_predicate(status, :success?, out)
      log = File.join(base, "target/entries-logs/#{name.delete_prefix('entries/')}.txt")
      assert_equal("unusual-name\n", File.read(log))
    end
  end

  private

  def with_entries(prefix = 'entries-')
    Dir.mktmpdir do |tmp|
      base = File.join(tmp, prefix)
      FileUtils.mkdir_p(File.join(base, 'makes'))
      base = File.realpath(base)
      FileUtils.cp(File.join(__dir__, '../makes/entries.sh'), File.join(base, 'makes/entries.sh'))
      write_script(base, 'entries/pass.sh', 'exit 0')
      yield(base)
    end
  end

  def write_script(base, name, body)
    path = File.join(base, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "#!/usr/bin/env bash\n#{body}\n")
    FileUtils.chmod(0o755, path)
  end

  def run_entries(base, env = {})
    Open3.capture2e(env, 'bash', File.join(base, 'makes/entries.sh'), chdir: base)
  end
end
