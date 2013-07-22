#!/usr/bin/make

all: misspell_fixer_safe.sed misspell_fixer_not_so_safe.sed

misspell_fixer_safe.sed: dict/misspell_fixer_safe.dict
	./dict/misspell_convert_dict_to_sed.pl <dict/misspell_fixer_safe.dict >./misspell_fixer_safe.sed

misspell_fixer_not_so_safe.sed: dict/misspell_fixer_not_so_safe.dict
	./dict/misspell_convert_dict_to_sed.pl <dict/misspell_fixer_not_so_safe.dict >./misspell_fixer_not_so_safe.sed

lint_dicts:
	sort -u ./dict/misspell_fixer_safe.dict >misspell_fixer_safe.dict.su
	sort -u ./dict/misspell_fixer_not_so_safe.dict >misspell_fixer_not_so_safe.dict.su
	comm -23 misspell_fixer_safe.dict.su misspell_fixer_not_so_safe.dict.su >./dict/misspell_fixer_safe.dict
	mv misspell_fixer_not_so_safe.dict.su ./dict/misspell_fixer_not_so_safe.dict
	rm misspell_fixer_safe.dict.su
