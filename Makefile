# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

.ONESHELL:
.PHONY: clean all assets install rake stylelint
.SILENT:
.SECONDARY:
.SHELLFLAGS := -x -e -o pipefail -c
SHELL := bash

OS_NAME := $(shell uname -s | tr A-Z a-z)

YAMLS = $(wildcard tests/*.yml)
FBS = $(subst tests/,target/fb/,${YAMLS:.yml=.fb})
HTMLS = $(subst fb/,html/,${FBS:.fb=.html})
XSLS = $(subst xsl/,target/xsl/,$(wildcard xsl/*.xsl))
JUDGES = bundle exec judges
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
	xpaths=$$( ruby -e 'require "yaml"; YAML.load_file(ARGV[0], permitted_classes: [Time])[0]["xpaths"].split("\n").each { |x| puts x }' "tests/$${n}.yml" )
	while IFS= read -r xpath; do
		xmllint --xpath "$${xpath}" "$$(dirname "$<")/$${n}/$${n}-vitals.html" > /dev/null
	done <<< "$${xpaths}"
	result=0
	tidy -e "$$(dirname "$@")/$${n}.html" || result=$?
	if [ "$${result}" -eq "2" ]; then
		echo "$$(dirname "$@")/$${n}.html has errors"
		exit 1
	fi
	tidy -e "$$(dirname "$@")/$${n}-vitals.html" || result=$?
	if [ "$${result}" -eq "2" ]; then
		echo "$$(dirname "$@")/$${n}-vitals.html has errors"
		exit 1
	fi

target/fb/%.fb: tests/%.yml Makefile | target/fb
	if [ -e "$@" ]; then $(JUDGES) trim --query='(always)' "$@"; fi
	$(JUDGES) import "$<" "$@"

rake: $(SAXON)
	bundle exec rake

stylelint: sass/*.scss
	stylelint sass/*.scss --fix

$(CSS): sass/*.scss stylelint Makefile | target/css
	sass --no-source-map --style=compressed --no-quiet --stop-on-error sass/main.scss "$@"

$(JS): js/*.js Makefile | target/js
	eslint js/*.js
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
	bundle install
	if [ "$(OS_NAME)" = "darwin" ]; then
		brew install tidy-html5
	else
		if ! ([ -f /proc/self/cgroup ] && grep -q ":" /proc/self/cgroup); then
			apt-get install -y tidy
		fi
	fi
	npm --no-color install -g eslint@9.22.0
	npm --no-color install -g uglify-js@3.19.3
	npm --no-color install -g sass@1.77.2
	npm --no-color install -g stylelint@16.15.0 stylelint-config-standard@37.0.0 stylelint-scss@6.11.1
	npm --no-color install -g html-minifier@4.0.0

entry: target/docker-image.txt target/fb/simple.fb
	img=$$(cat target/docker-image.txt)
	test -e target/fb/simple.fb
	docker run --rm \
	    "--user=$$(id -u):$$(id -g)" \
		-v "$$(realpath $$(pwd))/target/fb/:/work" \
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
	tree target/fb/
	test -e target/fb/pages/simple-vitals.html
	test -e target/fb/pages/simple.html
	test -e target/fb/pages/simple.xml
	test -e target/fb/pages/simple.json
	test -e target/fb/pages/simple.yaml

target/docker-image.txt: Makefile Dockerfile entry.sh
	mkdir -p "$$(dirname $@)"
	docker build -t pages-action "$$(pwd)"
	docker build -t pages-action -q "$$(pwd)" > "$@"

$(DIRS):
	mkdir -p "$@"
