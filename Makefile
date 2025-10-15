# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

.ONESHELL:
.PHONY: clean all assets install rake stylelint test entries
.SILENT:
.SECONDARY:
.SHELLFLAGS := -x -e -o pipefail -c
SHELL := bash

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

all: assets $(HTMLS) rake entry rmi verify entries

assets: $(XSLS) $(JS) $(CSS)

target/xsl/%.xsl: xsl/%.xsl | target/xsl
	cp "$<" "$@"

target/output/%: target/fb/%.fb entry.sh Makefile $(XSLS) $(CSS) $(JS) $(SAXON) | target/html
	export INPUT_VERBOSE=yes
	export INPUT_OPTIONS=testing=yes
	export GITHUB_WORKSPACE=.
	export INPUT_FACTBASE=$<
	export INPUT_ADLESS=false
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
	for f in $${n} $${n}-vitals; do
		result=0
		tidy -e "$$(dirname "$@")/$${f}.html" || result=$$?
		if [ "$${result}" -eq 2 ]; then
			echo "$$(dirname "$@")/$${f}.html has errors"
			exit 1
		fi
	done

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

entries: assets
	./makes/entries.sh

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
	./makes/install.sh

entry: target/docker-image.txt target/fb/simple.fb
	./makes/entry-in-docker.sh "$$(cat target/docker-image.txt)"
	echo "$$?" > target/entry.exit

rmi: target/docker-image.txt
	img=$$(cat $<)
	docker rmi "$${img}"
	rm "$<"

verify:
	./makes/verify.sh

target/docker-image.txt: Makefile Dockerfile entry.sh
	mkdir -p "$$(dirname $@)"
	docker build -t pages-action "$$(pwd)"
	docker build -t pages-action -q "$$(pwd)" > "$@"

$(DIRS):
	mkdir -p "$@"
