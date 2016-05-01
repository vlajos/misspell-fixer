#!/bin/bash

function remove_duplications {
	export actual=$1
	sort -u /tmp/already_processed.dict >/tmp/already_processed.dict.su
	sort -u misspell_fixer_$actual.dict >misspell_fixer_$actual.dict.su
	comm -23 misspell_fixer_$actual.dict.su /tmp/already_processed.dict.su >misspell_fixer_$actual.dict
	mv /tmp/already_processed.dict.su /tmp/already_processed.dict
	rm misspell_fixer_$actual.dict.su
}

sort -u misspell_fixer_safe.0.dict >/tmp/already_processed.dict
cp /tmp/already_processed.dict misspell_fixer_safe.0.dict

for i in safe.1 safe.2 safe.3 not_so_safe gb_to_us
do
    remove_duplications $i
done
