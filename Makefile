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
	sudo apt-get install -y elfutils libdw1/precise libasm1/precise libdw-dev/precise libelf-dev libcurl4-openssl-dev
	git clone https://github.com/kward/shunit2
	cd shunit2; git checkout 1a26843113f3be945ce4f5a04786b20ea83ae8a6
	cd /tmp;git clone https://github.com/SimonKagstrom/kcov
	cd /tmp/kcov;cmake ./;make;sudo make install
