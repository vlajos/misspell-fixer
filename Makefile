#!/usr/bin/make

.PHONY: test prepare_environment coveralls

all: lint_dicts $(wildcard *.sed)

%.sed: dict/%.dict
	./dict/misspell_convert_dict_to_sed.pl <$< >./$@

lint_dicts:
	cd dict;./misspell_lint_dicts.sh

test:
	/usr/local/bin/kcov --include-pattern=misspell_fixer.sh --path-strip-level=1 --coveralls-id=$(TRAVIS_JOB_ID) /tmp/coverage/ test/tests.sh

test_self:
	test/self_spelling_test.sh

prepare_environment:
	sudo apt-get update -qq
	sudo apt-get install -y elfutils libdw1 libasm1 libdw-dev libelf-dev libcurl4-openssl-dev
	curl -L "https://github.com/kward/shunit2/archive/v2.1.7.tar.gz" | tar zx
	cd /tmp;git clone https://github.com/SimonKagstrom/kcov
	cd /tmp/kcov;cmake ./;make;sudo make install

man:
	ronn --roff --manual=misspell-fixer README.md
	sed -i -e 's/README/misspell_fixer/g' -e '/travis/d' README 
	mv README doc/misspell_fixer.1
