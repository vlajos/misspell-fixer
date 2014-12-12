#! /bin/sh

export TEMP=/tmp/misspell_fixer_test/$$

oneTimeSetUp(){
    mkdir -p $TEMP $TEMP/work/ $TEMP/expected/
}

oneTimeTearDown(){
   rm -rf $TEMP
}

setUp(){
    cp -a test/stubs/* $TEMP/work/
    cp -a test/stubs/* $TEMP/expected/
}

testNoArg(){
    assertEquals "misspell_fixer: Not enought arguments. (target directory not found) => Exiting." "$(./misspell_fixer.sh 2>&1)"
}


runAndCompare(){
    ./misspell_fixer.sh $1 $TEMP/work
    while [ "$2" != "" ]
    do
        cp -a test/expecteds/$2.txt $TEMP/expected/
        shift
    done
    diff -ruwb $TEMP/expected/ $TEMP/work/
    assertTrue 'Expected output differs.' $?
}

testOnlyDir(){
    runAndCompare '';
}

testReal0NoBackup(){
    runAndCompare '-rn' '0'
}

testFast0(){
    runAndCompare '-frn' '0'
}
testFastR(){
    runAndCompare '-frnR' '0' 'R'
}
testFastV(){
    runAndCompare '-frnV' '0' 'V'
}
testFastu(){
    runAndCompare '-frnu' '0' 'u'
}
testFastg(){
    runAndCompare '-frng' '0' 'g'
}
testFastRVug(){
    runAndCompare '-frnRVug' '0' 'R' 'V' 'u' 'g'
}
testSpaceInFileName(){
    mv $TEMP/work/0.txt "$TEMP/work/0 0.txt"
    rm $TEMP/expected/0.txt
    cp -a test/expecteds/0.txt "$TEMP/expected/0 0.txt"
    ./misspell_fixer.sh -rn $TEMP/work
    diff -ruwb $TEMP/expected/ $TEMP/work/
    assertTrue 'Expected output differs.' $?
}


# load shunit2
. shunit2-2.1.6/src/shunit2
