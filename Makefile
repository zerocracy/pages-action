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
.PHONY: clean all install
.SILENT:

SHELL = bash

YAMLS = $(wildcard tests/*.yml)
FBS = $(subst tests/,target/fb/,${YAMLS:.yml=.fb})
HTMLS = $(subst fb/,html/,${FBS:.fb=.html})
XSLS = $(subst xsl/,target/xsl/,$(wildcard xsl/*.xsl))
JUDGES = judges
DIRS = target target/html target/fb target/xsl target/css
CSS = target/css/main.css

export

all: $(CSS) $(XSLS) $(HTMLS)

target/xsl/%.xsl: xsl/%.xsl | target/xsl
	cp $< $@

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

$(CSS): sass/*.scss | target
	sass --no-source-map --style=compressed --no-quiet --stop-on-error $< $@

clean:
	rm -rf target

install: target
	wget --no-verbose -O target/saxon.jar https://repo.maven.apache.org/maven2/net/sf/saxon/Saxon-HE/9.8.0-5/Saxon-HE-9.8.0-5.jar
	gem install judges:0.0.31
	npm install -g sass@1.77.2

$(DIRS):
	mkdir -p "$@"
