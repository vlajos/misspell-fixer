#! /bin/bash

export TEMP=/tmp/misspell_fixer_test/$$
export RUN=". misspell_fixer.sh"
export UNDERSHUNIT=1

oneTimeSetUp(){
	mkdir -p $TEMP $TEMP/work/ $TEMP/expected/
}

oneTimeTearDown(){
	rm -rf $TEMP
}

setUp(){
	set +f
	cp -a test/stubs/* $TEMP/work/
	cp -a test/stubs/* $TEMP/expected/
	set -f
}

runAndCompare(){
	$RUN $1 $TEMP/work
	assertTrue $?
	while [ "$2" != "" ]
	do
		cp -a test/expecteds/$2.txt $TEMP/expected/
		shift
	done
	diff -ruwb $TEMP/expected/ $TEMP/work/
	assertTrue 'Expected output differs.' $?
}

testNoArg(){
	TMP=$($RUN 2>&1)
	assertFalse $?
	echo $TMP|grep -q "misspell_fixer: Not enought arguments. (target directory not found) => Exiting."
	assertTrue 'No argument handling problem.' $?
}

testOnlyDir(){
	runAndCompare '';
}

testSpaceInFileName(){
	mv $TEMP/work/0.txt "$TEMP/work/0 0.txt"
	rm $TEMP/expected/0.txt
	cp -a test/expecteds/0.txt "$TEMP/expected/0 0.txt"
	$RUN -rn $TEMP/work
	diff -ruwb $TEMP/expected/ $TEMP/work/
	assertTrue 'Expected output differs.' $?
}

suite(){
    suite_addTest testNoArg
    suite_addTest testOnlyDir
    suite_addTest testSpaceInFileName
    for i in '' R V u g 'R V u g'
    do
        allarg=$(echo $i|sed 's/ //g')
        eval "testMainNormal$allarg(){ runAndCompare -rn$allarg 0 $i; }"
        suite_addTest testMainNormal$allarg
        eval "testMainFast$allarg(){ runAndCompare -frn$allarg 0 $i; }"
        suite_addTest testMainFast$allarg
    done
}


# load shunit2
. shunit2-2.1.6/src/shunit2
