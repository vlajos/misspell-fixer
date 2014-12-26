#!/usr/bin/make

.PHONY: test prepare_environment coveralls

all: lint_dicts $(wildcard *.sed)

%.sed: dict/%.dict
	./dict/misspell_convert_dict_to_sed.pl <$< >./$@

lint_dicts:
	cd dict;./misspell_lint_dicts.sh

test:
	/usr/local/bin/kcov --include-pattern=misspell_fixer.sh --path-strip-level=1 /tmp/coverage/ test/tests.sh

prepare_environment:
	sudo apt-get update -qq
	sudo apt-get install -y libdw-dev libelf-dev elfutils
	curl -L "https://shunit2.googlecode.com/files/shunit2-2.1.6.tgz" | tar zx
	cd /tmp;git clone https://github.com/SimonKagstrom/kcov
	cd /tmp/kcov;cmake ./;make;sudo make install
	wget http://lavela.hu/kcov2coveralls.sh -O /tmp/kcov2coveralls.sh
	chmod a+x /tmp/kcov2coveralls.sh

coveralls:
	/tmp/kcov2coveralls.sh /tmp/coverage/tests.sh/ >/tmp/coveralls.json
	curl  -F 'json_file=@/tmp/coveralls.json' https://coveralls.io/api/v1/jobs
