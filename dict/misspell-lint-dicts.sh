#!/bin/bash -x

function remove_duplications {
	export actual=$1
	sort -d -f -u /tmp/already-processed.dict > /tmp/already-processed.dict.su
	sort -d -f -u "misspell-fixer-$actual.dict" > "misspell-fixer-$actual.dict.su"
	comm -23 "misspell-fixer-$actual.dict.su" /tmp/already-processed.dict.su > "misspell-fixer-$actual.dict"
	mv /tmp/already-processed.dict.su /tmp/already-processed.dict
	rm "misspell-fixer-$actual.dict.su"
}

sort -d -f -u misspell-fixer-safe.0.dict >/tmp/already-processed.dict
cp /tmp/already-processed.dict misspell-fixer-safe.0.dict

for i in safe.1 safe.2 safe.3 not-so-safe gb-to-us
do
    remove_duplications $i
done
