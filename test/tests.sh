#! /bin/bash

export TEMP=/tmp/misspell_fixer_test/$$
export RUN=". misspell_fixer.sh"

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

testErrors(){
	TMP=$($RUN 2>&1)
	assertFalse $?
	echo $TMP|grep -q "misspell_fixer: Not enought arguments. (target directory not found) => Exiting."
	assertTrue 'No argument handling problem.' $?
	$RUN -h
	assertFalse $?
	$RUN -p /dev/null
	assertFalse $?
	$RUN -P
	assertFalse $?
	$RUN -f /dev/null
	assertFalse $?
	$RUN -fr /dev/null
	assertFalse $?
	$RUN -frns /dev/null
	assertFalse $?
	$RUN -frnv /dev/null
	assertFalse $?
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
	rm "$TEMP/work/0 0.txt" "$TEMP/expected/0 0.txt"
}

testShowDiff(){
	$RUN -s $TEMP/work|sed 's/[0-9]\+/X/g' >/tmp/diffoutput
	diff -ruwb $TEMP/expected/ $TEMP/work/
	assertTrue 'Expected output differs.' $?
	diff -ruwb /tmp/diffoutput test/expected.diff.output
	assertTrue 'Expected output differs.' $?
}

testParallel(){
	runAndCompare -frnP4 0
}

testBackup(){
	$RUN -r $TEMP/work
	assertTrue $?
	diff -ruwb test/expecteds/0.txt $TEMP/work/0.txt
	assertTrue 'Expected output differs.' $?
	set +f
	diff -ruwb test/stubs/0.txt $TEMP/work/0.txt*BAK
	assertTrue 'Backup mismatch.' $?
	rm $TEMP/work/0.txt*BAK
	set -f
}

testSCMdirsuntouched(){
	mkdir $TEMP/work/.git/
	cp test/stubs/0.txt $TEMP/work/.git/0.txt
	$RUN -rn $TEMP/work
	assertTrue $?
	diff -ruwb test/expecteds/0.txt $TEMP/work/0.txt
	assertTrue 'Expected output differs.' $?
	diff -ruwb test/stubs/0.txt $TEMP/work/.git/0.txt
	assertTrue 'SCM dir differs.' $?
	rm -rf $TEMP/work/.git/
}

testSCMdirstouched(){
	mkdir $TEMP/work/.git/
	cp test/stubs/0.txt $TEMP/work/.git/0.txt
	$RUN -rni $TEMP/work
	assertTrue $?
	diff -ruwb test/expecteds/0.txt $TEMP/work/0.txt
	assertTrue 'Expected output differs.' $?
	diff -ruwb test/expecteds/0.txt $TEMP/work/.git/0.txt
	assertTrue 'SCM dir unchanged.' $?
	rm -rf $TEMP/work/.git/
}

testNamefilter(){
	cp test/stubs/0.txt $TEMP/work/0.xxx
	cp test/stubs/0.txt $TEMP/work/0.yyy
	$RUN -rni -N '*.xxx' -N '*.yyy' $TEMP/work
	assertTrue $?
	diff -ruwb test/stubs/0.txt $TEMP/work/0.txt
	assertTrue 'Expected output differs.' $?
	diff -ruwb test/expecteds/0.txt $TEMP/work/0.xxx
	assertTrue 'Expected output differs.' $?
	diff -ruwb test/expecteds/0.txt $TEMP/work/0.yyy
	assertTrue 'Expected output differs.' $?
	rm -rf $TEMP/work/0.xxx $TEMP/work/0.yyy
}

testKeepPermissionsNormal(){
	tests=(0000 777u 444g 222R 111V)
	for i in ${tests[*]}
	do
		chmod ${i:0:3} $TEMP/work/${i:3}.txt
	done
	$RUN -fnuVG $TEMP/work
	for i in ${tests[*]}
	do
		chmod ${i:0:3} $TEMP/work/${i:3}.txt |grep -q changed
		assertFalse "Permissions broken:$i" $?
		chmod 644 $TEMP/work/${i:3}.txt
	done
	diff -ruwb $TEMP/expected/ $TEMP/work/
	assertTrue 'Expected output differs.' $?
}

testKeepPermissionsFast(){
	tests=(0000 777u 444g 222R 111V)
	for i in ${tests[*]}
	do
		chmod ${i:0:3} $TEMP/work/${i:3}.txt
	done
	$RUN -frnuVG $TEMP/work
	for i in ${tests[*]}
	do
		chmod ${i:0:3} $TEMP/work/${i:3}.txt |grep -q changed
		assertFalse "Permissions broken:$i" $?
		chmod 644 $TEMP/work/${i:3}.txt
	done
	diff -ruwb $TEMP/expected/ $TEMP/work/
	assertTrue 'Expected output differs.' $?
}

suite(){
	suite_addTest testErrors
	suite_addTest testOnlyDir
	suite_addTest testSpaceInFileName
	suite_addTest testShowDiff
	suite_addTest testParallel
	suite_addTest testBackup
	suite_addTest testSCMdirsuntouched
	suite_addTest testSCMdirstouched
	suite_addTest testNamefilter
	suite_addTest testKeepPermissionsNormal
	suite_addTest testKeepPermissionsFast
	for i in '' R V u g 'R V u g'
	do
		allarg=${i// }
		eval "testMainNormal$allarg(){ runAndCompare -rn$allarg 0 $i; }"
		suite_addTest testMainNormal$allarg
		eval "testMainFast$allarg(){ runAndCompare -frn$allarg 0 $i; }"
		suite_addTest testMainFast$allarg
	done
}


# load shunit2
. shunit2-2.1.6/src/shunit2
