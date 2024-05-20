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

.SHELLFLAGS: -e -o pipefail -c
.ONESHELL:
.PHONY: clean all
.SILENT:

VERSION = 0.0.0

SHELL = bash

YAMLS = $(wildcard tests/*.yml)
FBS = $(subst tests/,target/fb/,${YAMLS:.yml=.fb})
HTMLS = $(subst fb/,html/,${FBS:.fb=.html})
JUDGES = /code/gems/judges/bin/judges
DIRS = target target/html target/fb

export

all: $(HTMLS)

target/html/%.html: target/fb/%.fb xsl/*.xsl entry.sh Makefile target/css/main.css | target/html
	export INPUT_VERBOSE=yes
	export GITHUB_WORKSPACE=.
	export INPUT_FACTBASE=$<
	fb=$$(basename $<)
	fb=$${fb%.*}
	export INPUT_OUTPUT=target/output/$${fb}
	./entry.sh
	cp target/output/$${fb}/$${fb}.html target/html

target/fb/%.fb: tests/%.yml Makefile | target/fb
	$(JUDGES) import $< $@

target/css/main.css: sass/*.scss | target
	sass --no-source-map --style=compressed --no-quiet --stop-on-error $< $@

clean:
	rm -rf target

$(DIRS):
	mkdir -p "$@"
