#!/usr/bin/make

all: misspell_fixer_safe.0.sed misspell_fixer_safe.1.sed misspell_fixer_safe.2.sed misspell_fixer_not_so_safe.sed misspell_fixer_gb_to_us.sed

misspell_fixer_safe.0.sed: dict/misspell_fixer_safe.0.dict
	./dict/misspell_convert_dict_to_sed.pl <dict/misspell_fixer_safe.0.dict >./misspell_fixer_safe.0.sed

misspell_fixer_safe.1.sed: dict/misspell_fixer_safe.1.dict
	./dict/misspell_convert_dict_to_sed.pl <dict/misspell_fixer_safe.1.dict >./misspell_fixer_safe.1.sed

misspell_fixer_safe.2.sed: dict/misspell_fixer_safe.2.dict
	./dict/misspell_convert_dict_to_sed.pl <dict/misspell_fixer_safe.2.dict >./misspell_fixer_safe.2.sed

misspell_fixer_not_so_safe.sed: dict/misspell_fixer_not_so_safe.dict
	./dict/misspell_convert_dict_to_sed.pl <dict/misspell_fixer_not_so_safe.dict >./misspell_fixer_not_so_safe.sed

misspell_fixer_gb_to_us.sed: dict/misspell_fixer_gb_to_us.dict
	./dict/misspell_convert_dict_to_sed.pl <dict/misspell_fixer_gb_to_us.dict >./misspell_fixer_gb_to_us.sed

lint_dicts:
	sort -u ./dict/misspell_fixer_safe.dict >misspell_fixer_safe.dict.su
	sort -u ./dict/misspell_fixer_not_so_safe.dict >misspell_fixer_not_so_safe.dict.su
	comm -23 misspell_fixer_safe.dict.su misspell_fixer_not_so_safe.dict.su >./dict/misspell_fixer_safe.dict
	mv misspell_fixer_not_so_safe.dict.su ./dict/misspell_fixer_not_so_safe.dict
	rm misspell_fixer_safe.dict.su
