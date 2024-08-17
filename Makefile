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

.ONESHELL:
.PHONY: clean all assets install rake
.SILENT:
.SHELLFLAGS := -x -e -o pipefail -c
SHELL := bash

YAMLS = $(wildcard tests/*.yml)
FBS = $(subst tests/,target/fb/,${YAMLS:.yml=.fb})
HTMLS = $(subst fb/,html/,${FBS:.fb=.html})
XSLS = $(subst xsl/,target/xsl/,$(wildcard xsl/*.xsl))
JUDGES = judges
DIRS = target target/html target/fb target/xsl target/css target/js
CSS = target/css/main.css
JS = target/js/main.js
SAXON = target/saxon.jar

export

all: assets $(HTMLS) rake entry rmi verify

assets: $(XSLS) $(JS) $(CSS)

target/xsl/%.xsl: xsl/%.xsl | target/xsl
	cp "$<" "$@"

target/output/%: target/fb/%.fb entry.sh Makefile $(XSLS) $(CSS) $(JS) $(SAXON) | target/html
	export INPUT_VERBOSE=yes
	export INPUT_OPTIONS=testing=yes
	export GITHUB_WORKSPACE=.
	export INPUT_FACTBASE=$<
	export INPUT_COLUMNS=what,when,who
	export INPUT_HIDDEN=_id,_time,_version
	export INPUT_TODAY='2024-07-05T00:00:00Z'
	fb=$$(basename $<)
	fb=$${fb%.*}
	export INPUT_OUTPUT=target/output/$${fb}
	./entry.sh

target/html/%.html: target/output/%
	n=$$(basename "$@")
	n=$${n%.*}
	cp "$$(dirname "$<")/$${n}/$${n}.html" "$$(dirname "$@")/$${n}.html"
	cp "$$(dirname "$<")/$${n}/$${n}-vitals.html" "$$(dirname "$@")/$${n}-vitals.html"

target/fb/%.fb: tests/%.yml Makefile | target/fb
	if [ -e "$@" ]; then $(JUDGES) trim --query='(always)' "$@"; fi
	$(JUDGES) import "$<" "$@"

rake:
	bundle exec rake

$(CSS): sass/*.scss Makefile | target/css
	sass --no-source-map --style=compressed --no-quiet --stop-on-error sass/main.scss "$@"

$(JS): js/*.js Makefile | target/js
	uglifyjs js/*.js > "$@"

clean:
	rm -rf target

$(SAXON): | target
	p=net/sf/saxon/Saxon-HE/9.8.0-5/Saxon-HE-9.8.0-5.jar
	m2=$${HOME}/.m2/repository/$${p}
	if [ -e "$${m2}" ]; then
		cp "$${m2}" "$(SAXON)"
	else
		wget --no-verbose -O "$(SAXON)" "https://repo.maven.apache.org/maven2/$${p}"
	fi

install: $(SAXON) | target
	bundle update
	npm --no-color install -g uglify-js
	npm --no-color install -g sass@1.77.2

entry: target/docker-image.txt target/fb/simple.fb
	img=$$(cat target/docker-image.txt)
	test -e target/fb/simple.fb
	docker run --rm -v "$$(realpath $$(pwd))/target/fb/:/work" \
		-e GITHUB_WORKSPACE=/work \
		-e INPUT_FACTBASE=simple.fb \
		-e INPUT_VERBOSE=true \
		-e INPUT_OUTPUT=pages \
		-e INPUT_COLUMNS=what,when,who \
		-e INPUT_HIDDEN=_id \
		"$${img}"
	echo "$$?" > target/entry.exit

rmi: target/docker-image.txt
	img=$$(cat $<)
	docker rmi "$${img}"
	rm "$<"

verify:
	e2=$$(cat target/entry.exit)
	test "$${e2}" = "0"
	test -e target/fb/pages/simple-vitals.html
	test -e target/fb/pages/simple.html
	test -e target/fb/pages/simple.xml
	test -e target/fb/pages/simple.json
	test -e target/fb/pages/simple.yaml

target/docker-image.txt: Makefile Dockerfile entry.sh
	mkdir -p "$$(dirname $@)"
	sudo docker build -t pages-action "$$(pwd)"
	sudo docker build -t pages-action -q "$$(pwd)" > "$@"

$(DIRS):
	mkdir -p "$@"
