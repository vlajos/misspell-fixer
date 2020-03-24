#!/usr/bin/env bash

export TEMP=/tmp/misspell-fixer-test/$$
export RUN=". $PWD/misspell-fixer"
export LC_ALL=C

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
    cd "$TEMP"
    $RUN "$1" work
    assertFalse $?
    cd -
    while [ "$2" != "" ]; do
        cp -a "test/expecteds/$2.txt" $TEMP/expected/
        shift
    done
    diff -ruwb $TEMP/expected/ $TEMP/work/
    assertTrue 'Expected output differs.' $?
}

runAndCompareOutput(){
    export TEST_OUTPUT=$TEMP/output.$2

    cd "$TEMP"
    $RUN "$1" "work" >>"$TEST_OUTPUT" 2>&1
    cd -
    diff -ruwb $TEMP/expected/ $TEMP/work/
    assertTrue 'Expected output differs.' $?

    sed -e 's/[0-9]\+/X/g' -e 's/X -X$/X +X/g' "$TEST_OUTPUT" |\
    grep -v -e kcov -e 'grep -vh bin/sed' -e "Your grep version is" \
        >"$TEST_OUTPUT.standard"
    if [[ "$3" = "1" ]]; then
        sort -f "$TEST_OUTPUT.standard" >"$TEST_OUTPUT.standard.sorted"
        mv "$TEST_OUTPUT.standard.sorted" "$TEST_OUTPUT.standard"
    fi
    diff -ruwb "$TEST_OUTPUT.standard" "test/expected.$2.output"
    assertTrue 'Expected output differs.' $?
    rm "$TEST_OUTPUT" "$TEST_OUTPUT.standard"
}

testErrors(){
    TMP=$($RUN 2>&1)
    assertSame 102 $?
    echo "$TMP"|\
        grep -q\
        "misspell-fixer: Not enough arguments."
    assertTrue 'No argument handling problem.' $?
    $RUN -h
    assertSame 10 $?
    $RUN -p /dev/null
    assertSame 100 $?
    $RUN -P
    assertSame 101 $?
    $RUN -fs /dev/null
    assertSame 104 $?
}

testOnlyDir(){
    runAndCompare '';
}

testSpaceInFileName(){
    mv $TEMP/work/0.txt "$TEMP/work/0 0.txt"
    rm $TEMP/expected/0.txt
    cp -a test/expecteds/0.txt "$TEMP/expected/0 0.txt"
    cd $TEMP
    $RUN -rn work
    cd -
    diff -ruwb $TEMP/expected/ $TEMP/work/
    assertTrue 'Expected output differs.' $?
    rm "$TEMP/work/0 0.txt" "$TEMP/expected/0 0.txt"
}

testMultipleFileNames(){
    cp $TEMP/work/0.txt $TEMP/work/1.txt
    cp -a test/expecteds/0.txt $TEMP/expected/0.txt
    cp -a test/expecteds/0.txt $TEMP/expected/1.txt
    cd $TEMP
    $RUN -rn work/0.txt work/1.txt
    cd -
    diff -ruwb $TEMP/expected/ $TEMP/work/
    assertTrue 'Expected output differs.' $?
    rm $TEMP/work/1.txt $TEMP/expected/1.txt
}

testShowDiff(){
    runAndCompareOutput -s diff
}

testParallel(){
    runAndCompare -frnP4 0
}

testBackup(){
    cd $TEMP
    $RUN -r work
    assertFalse $?
    cd -
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
    cd $TEMP
    $RUN -rn work
    assertFalse $?
    cd -
    diff -ruwb test/expecteds/0.txt $TEMP/work/0.txt
    assertTrue 'Expected output differs.' $?
    diff -ruwb test/stubs/0.txt $TEMP/work/.git/0.txt
    assertTrue 'SCM dir differs.' $?
    rm -rf $TEMP/work/.git/
}

testSCMdirstouched(){
    mkdir $TEMP/work/.git/
    cp test/stubs/0.txt $TEMP/work/.git/0.txt
    cd $TEMP
    $RUN -rni work
    assertFalse $?
    cd -
    diff -ruwb test/expecteds/0.txt $TEMP/work/0.txt
    assertTrue 'Expected output differs.' $?
    diff -ruwb test/expecteds/0.txt $TEMP/work/.git/0.txt
    assertTrue 'SCM dir unchanged.' $?
    rm -rf $TEMP/work/.git/
}

testGitIgnoreNotRespected(){
    cd $TEMP/work/
    git init
    echo 0.txt >.gitignore
    cd -
    cp test/stubs/0.txt $TEMP/work/0.txt
    cd $TEMP/work
    $RUN -rn .
    assertFalse $?
    cd -
    diff -ruwb test/expecteds/0.txt $TEMP/work/0.txt
    assertTrue 'Gitignore respected.' $?
    rm -rf $TEMP/work/.git/ $TEMP/work/.gitignore $TEMP/work/0.txt
}

testGitIgnoreRespected(){
    cd $TEMP/work/
    git init
    echo 0.txt >.gitignore
    cd -
    cp test/stubs/0.txt $TEMP/work/0.txt
    cd $TEMP/work
    $RUN -rnG .
    assertTrue $?
    cd -
    diff -ruwb test/stubs/0.txt $TEMP/work/0.txt
    assertTrue 'Gitignore not respected.' $?
    rm -rf $TEMP/work/.git/ $TEMP/work/.gitignore $TEMP/work/0.txt
}

testNamefilter(){
    cp test/stubs/0.txt $TEMP/work/0.aaa
    cp test/stubs/0.txt $TEMP/work/0.yyy
    cp test/stubs/0.txt $TEMP/work/0.zzz
    cd $TEMP
    $RUN -rni -N '*.aaa' -N '*.yyy' work
    assertFalse $?
    cd -
    diff -ruwb test/stubs/0.txt $TEMP/work/0.txt
    assertTrue 'Expected output differs.' $?
    diff -ruwb test/expecteds/0.txt $TEMP/work/0.aaa
    assertTrue 'Expected output differs.' $?
    diff -ruwb test/expecteds/0.txt $TEMP/work/0.yyy
    assertTrue 'Expected output differs.' $?
    diff -ruwb test/expecteds/0.txt $TEMP/work/0.zzz
    assertFalse 'Expected output equal?.' $?
    rm -rf $TEMP/work/0.aaa $TEMP/work/0.yyy $TEMP/work/0.zzz
}

testKeepPermissionsNormal(){
    tests=(0000 777u 444g 222R 111V)
    for i in ${tests[*]}; do
        chmod "${i:0:3}" "$TEMP/work/${i:3}.txt"
    done
    cd $TEMP
    $RUN -fnuVG work
    cd -
    for i in ${tests[*]}; do
        chmod "${i:0:3}" "$TEMP/work/${i:3}.txt" |grep -q changed
        assertFalse "Permissions broken:$i" $?
        chmod 644 "$TEMP/work/${i:3}.txt"
    done
    diff -ruwb $TEMP/expected/ $TEMP/work/
    assertTrue 'Expected output differs.' $?
}

testKeepPermissionsFast(){
    tests=(0000 777u 444g 222R 111V)
    for i in ${tests[*]}; do
        chmod "${i:0:3}" "$TEMP/work/${i:3}.txt"
    done
    cd $TEMP
    $RUN -frnuVG work
    cd -
    for i in ${tests[*]}; do
        chmod "${i:0:3}" "$TEMP/work/${i:3}.txt" |grep -q changed
        assertFalse "Permissions broken:$i" $?
        chmod 644 "$TEMP/work/${i:3}.txt"
    done
    diff -ruwb $TEMP/expected/ $TEMP/work/
    assertTrue 'Expected output differs.' $?
}

testIgnoreBinary(){
    tests=(gif jpg png gz zip rar)
    for i in ${tests[*]}; do
        cp test/stubs/0.txt "$TEMP/work/0.$i"
    done
    cd $TEMP
    $RUN -rn work
    cd -
    for i in ${tests[*]}; do
        diff -uwb test/stubs/0.txt "$TEMP/work/0.$i"
        assertTrue "Binary files changed:$i" $?
    done
    cd $TEMP
    $RUN -rnb work
    cd -
    for i in ${tests[*]}; do
        diff -uwb test/expecteds/0.txt "$TEMP/work/0.$i"
        assertTrue "Binary files unchanged:$i" $?
        rm "$TEMP/work/0.$i"
    done
}

testVerbose(){
    runAndCompareOutput -v verbose
}

testDebug(){
    runAndCompareOutput -d debug 1
}

testDots(){
    runAndCompareOutput -o dots
}

testMNoChange(){
    cp test/nochange.txt $TEMP/work/
    cp test/nochange.txt $TEMP/expected/
    cd $TEMP
    $RUN -mvRV work
    cd -
    diff -ruwb $TEMP/expected/ $TEMP/work/
    assertTrue 'Expected output differs.' $?
    rm -rf $TEMP/work/nochange.txt $TEMP/expected/nochange.txt
}

testWhitelistConflictWithRealRun(){
    runAndCompareOutput -rW whitelist_vs_real
}

testWhitelist(){
    cp test/stubs/0.txt $TEMP/work/0.txt
    cp test/stubs/0.txt $TEMP/expected/0.txt
    local whitelist=".misspell-fixer.ignore"
    cd $TEMP
    assertFalse 'Whitelist should not exist' "[ -s $whitelist ]"
    $RUN -W work
    assertTrue 'Whitelist should exist' "[ -s $whitelist ]"
    cd -
    cp test/stubs/0.txt $TEMP/work/1.txt
    cp test/expecteds/0.txt $TEMP/expected/1.txt
    runAndCompare -rn
    cd $TEMP
    rm $whitelist
    cd -
}

suite(){
    export TEST_OUTPUT=$TEMP/output.default
    suite_addTest testWhitelist
    suite_addTest testWhitelistConflictWithRealRun
    suite_addTest testShowDiff
    suite_addTest testErrors
    suite_addTest testOnlyDir
    suite_addTest testSpaceInFileName
    suite_addTest testMultipleFileNames
    suite_addTest testParallel
    suite_addTest testBackup
    suite_addTest testSCMdirsuntouched
    suite_addTest testSCMdirstouched
    suite_addTest testNamefilter
    suite_addTest testKeepPermissionsNormal
    suite_addTest testKeepPermissionsFast
    suite_addTest testIgnoreBinary
    suite_addTest testVerbose
    suite_addTest testDots
    suite_addTest testMNoChange
    for i in '' R V u g 'R V D' 'R V u g D'; do
        allarg=${i// }
        eval "testMainNormal$allarg(){ runAndCompare -rn$allarg 0 $i; }"
        suite_addTest "testMainNormal$allarg"
        eval "testMainFast$allarg(){ runAndCompare -frn$allarg 0 $i; }"
        suite_addTest "testMainFast$allarg"
    done
    if command -v git >/dev/null 2>/dev/null
    then
        suite_addTest testGitIgnoreNotRespected
        suite_addTest testGitIgnoreRespected
    else
        echo 'Git is not available so we do not test .gitignore related functionality.'
    fi
    if [[ "$COVERAGE_WRAPPER" = "" ]]; then
        suite_addTest testDebug
    else
        echo "Skipping testDebug under kcov."\
            "Set -x does not cascade through all the processes unfortunately."
    fi
}


# load shunit2
. ${SHUNIT_PREFIX}shunit2 >&2
