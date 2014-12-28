#!/usr/bin/make

.PHONY: test prepare_environment coveralls

all: lint_dicts $(wildcard *.sed)

%.sed: dict/%.dict
	./dict/misspell_convert_dict_to_sed.pl <$< >./$@

lint_dicts:
	cd dict;./misspell_lint_dicts.sh

test:
	/usr/local/bin/kcov --include-pattern=misspell_fixer.sh --path-strip-level=1 --coveralls-id=$(TRAVIS_JOB_ID) /tmp/coverage/ test/tests.sh

prepare_environment:
	sudo apt-get update -qq
	sudo apt-get install -y libdw-dev libelf-dev elfutils libcurl4-openssl-dev
	curl -L "https://shunit2.googlecode.com/files/shunit2-2.1.6.tgz" | tar zx
	cd /tmp;git clone https://github.com/SimonKagstrom/kcov
	cd /tmp/kcov;cmake ./;make;sudo make install
