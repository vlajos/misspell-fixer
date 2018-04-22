#!/usr/bin/make

.PHONY: test prepare_environment coveralls

all: lint_dicts $(wildcard *.sed)

%.sed: dict/%.dict
	./dict/misspell-convert-dict-to-sed.pl <$< >./$@
	chmod a+x ./$@

lint_dicts:
	cd dict;./misspell-lint-dicts.sh

KCOV=/usr/local/bin/kcov
KCOV_ARGS=--include-pattern=misspell-fixer/misspell-fixer --path-strip-level=1
COV_DIR=/tmp/coverage
test:
	export COVERAGE_WRAPPER="${KCOV} ${KCOV_ARGS} ${COV_DIR}-forks test/coverage_wrapper.sh";\
	${KCOV} ${KCOV_ARGS} ${COV_DIR}-main test/tests.sh;\
	${KCOV} ${KCOV_ARGS} --coveralls-id=${TRAVIS_JOB_ID} --merge ${COV_DIR} ${COV_DIR}-main ${COV_DIR}-forks

test_self:
	test/self-spelling-test.sh

prepare_environment:
	sudo apt-get update -qq
	sudo apt-get install -y elfutils libdw1 libasm1 libdw-dev libelf-dev libcurl4-openssl-dev
	curl -L "https://github.com/kward/shunit2/archive/v2.1.7.tar.gz" | tar zx
	cd /tmp;git clone https://github.com/SimonKagstrom/kcov
	cd /tmp/kcov;cmake ./;make;sudo make install

man:
	ronn --roff --manual=misspell-fixer README.md
	sed -i -e 's/README/misspell-fixer/g' -e '/travis/d' README 
	sed -i '/.TH /a .SH NAME\
	misspell-fixer \- misspell-fixer' README
	mv README doc/misspell-fixer.1
