# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative 'test__helper'

class TestEntrySize < Minitest::Test
  def test_passes_the_binary_size_after_the_judges_update_to_the_renderer
    source = File.expand_path('..', __dir__)
    saxon = File.join(source, 'target/saxon.jar')
    skip("Saxon not built at #{saxon}") unless File.exist?(saxon)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(%w[bin target/css target/js].map { |path| File.join(dir, path) })
      FileUtils.ln_s(File.join(source, 'xsl'), File.join(dir, 'target/xsl'))
      FileUtils.ln_s(saxon, File.join(dir, 'target/saxon.jar'))
      File.write(File.join(dir, 'target/css/main.css'), 'body{}')
      File.write(File.join(dir, 'target/js/main.js'), '')
      input = File.join(dir, 'input facts.fb')
      File.write(input, 'я' * 10_000)
      File.write(
        File.join(dir, 'bin/judges'),
        <<~SH
          #!/usr/bin/env bash
          set -eu
          case "$1" in
            update) printf 'updated' >> "${@: -1}" ;;
            print) printf '<fb size="1"><f><note>hello</note></f></fb>' > "${@: -1}" ;;
          esac
        SH
      )
      File.write(File.join(dir, 'bin/bundle'), "#!/usr/bin/env bash\nprintf '  * fbe (0.0.50)\\n'\n")
      File.write(File.join(dir, 'bin/html-minifier'), "#!/usr/bin/env bash\nexit 0\n")
      %w[judges bundle html-minifier].each { |file| FileUtils.chmod(0o755, File.join(dir, 'bin', file)) }
      stdout, stderr, status = Open3.capture3(
        {
          'PATH' => "#{dir}/bin:#{ENV.fetch('PATH')}",
          'JUDGES' => File.join(dir, 'bin/judges'),
          'GITHUB_WORKSPACE' => dir,
          'INPUT_FACTBASE' => input,
          'INPUT_OUTPUT' => 'output',
          'INPUT_URL' => 'https://example.com',
          'INPUT_ADLESS' => 'true',
          'INPUT_VERBOSE' => 'false',
          'INPUT_TODAY' => '2026-11-01T12:00:00Z',
          'LATEST_VERSION' => '0.0.1'
        },
        'bash', File.join(source, 'entry.sh'), dir
      )
      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
      html = File.read(File.join(dir, 'output/input facts-vitals.html'))
      assert_includes(html, "title=\"#{File.size(input)} bytes\"")
      assert_includes(html, '20kB</span>')
    end
  end
end
