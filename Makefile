#!/usr/bin/make

.PHONY: test prepare_environment coveralls

all: lint_dicts $(wildcard rules/*.sed)

rules/%.sed: dict/%.dict
	./util/convert-dict-to-sed.pl <$< >./$@
	chmod a+x ./$@

lint_dicts:
	./util/lint-dicts.sh

ifeq ($(wildcard /usr/local/bin/kcov),)
    KCOV_BIN = kcov
else
    KCOV_BIN = /usr/local/bin/kcov
endif

ifeq ($(wildcard shunit2-2.1.7),)
    SHUNIT_PREFIX = ""
else
    SHUNIT_PREFIX = shunit2-2.1.7/
endif

KCOV=${KCOV_BIN} --include-pattern=misspell-fixer/misspell-fixer,misspell-fixer/lib --path-strip-level=1
COV_DIR=/tmp/coverage
KCOV_WITH_ENV=env -i COVERAGE_WRAPPER="${KCOV} ${COV_DIR}-forks $(CURDIR)/test/coverage_wrapper.sh" SHUNIT_PREFIX=${SHUNIT_PREFIX} ${KCOV}
test_with_coverage:
	${KCOV_WITH_ENV} ${COV_DIR}-main test/tests.sh &&\
	${KCOV_WITH_ENV} --coveralls-id=${TRAVIS_JOB_ID} --merge ${COV_DIR} ${COV_DIR}-main ${COV_DIR}-forks

test:
	/bin/bash -c 'source test/tests.sh'

test_self:
	env -i SHUNIT_PREFIX=${SHUNIT_PREFIX}test/self-spelling-test.sh

prepare_environment:
	sudo apt-get update -qq
	sudo apt-get install -y elfutils libdw1 libasm1 libdw-dev libelf-dev libcurl4-openssl-dev cmake g++ zlib1g-dev python3
	curl -L "https://github.com/kward/shunit2/archive/v2.1.7.tar.gz" | tar zx
	cd /tmp;git clone https://github.com/SimonKagstrom/kcov
	cd /tmp/kcov;cmake ./;make;sudo make install

man:
	ronn --roff --manual=misspell-fixer README.md
	sed -i -e 's/README/misspell-fixer/g' -e '/travis/d' -e '/Jump to docker/d' README
	sed -i '/.TH /a .SH NAME\
	misspell-fixer \- misspell-fixer' README
	mv README doc/misspell-fixer.1
