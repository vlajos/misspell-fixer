#!/usr/bin/make

all: misspell_fixer_safe.sed misspell_fixer_not_so_safe.sed

misspell_fixer_safe.sed: dict/misspell_fixer_safe.dict
	./dict/misspell_convert_dict_to_sed.pl <dict/misspell_fixer_safe.dict >./misspell_fixer_safe.sed

misspell_fixer_not_so_safe.sed: dict/misspell_fixer_not_so_safe.dict
	./dict/misspell_convert_dict_to_sed.pl <dict/misspell_fixer_not_so_safe.dict >./misspell_fixer_not_so_safe.sed
