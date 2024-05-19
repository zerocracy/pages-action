# MIT License
#
# Copyright (c) 2024 Zerocracy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

.SHELLFLAGS: -c
.ONESHELL:
.PHONY: clean entry test
SAXON=/usr/local/Saxon.jar

entry: target/foo.fb test
	export GITHUB_WORKSPACE=.
	export INPUT_FACTBASE=target/foo.fb
	export INPUT_PAGES=target/pages
	./entry.sh

target/foo.fb: Makefile
	mkdir -p target/judges/foo
	echo '$$fb.insert.foo = 42' > target/judges/foo/foo.rb
	judges update --max-cycles 5 target/judges $@

test:
	mkdir -p target/html
	for i in $$(ls tests/*.xml); do
		name=$$(basename "$${i%.*}")
		java -jar "$(SAXON)" "-s:$${i}" -xsl:xsl/index.xsl "-o:target/html/$${name}.html"
	done

clean:
	rm -rf target
