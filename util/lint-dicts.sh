#!/bin/bash -x

function remove_duplications {
	export actual=$1
	sort -d -f -u /tmp/already-processed.dict > /tmp/already-processed.dict.su
	sort -d -f -u "dict/$actual.dict" > "dict/$actual.dict.su"
	comm -23 "dict/$actual.dict.su" /tmp/already-processed.dict.su > "dict/$actual.dict"
	mv /tmp/already-processed.dict.su /tmp/already-processed.dict
	rm "dict/$actual.dict.su"
}

sort -d -f -u dict/safe.0.dict >/tmp/already-processed.dict
cp /tmp/already-processed.dict dict/safe.0.dict

for i in safe.1 safe.2 safe.3 not-so-safe gb-to-us
do
    remove_duplications $i
done
