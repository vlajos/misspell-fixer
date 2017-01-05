#! /bin/bash

export TEMP=/tmp/misspell_fixer_test/$$
export RUN=". misspell_fixer.sh"
export LC_ALL=C
export SPELLING_ERR="$TEMP/self/spelling.txt"

oneTimeSetUp(){
	mkdir -p $TEMP $TEMP/self/
}

oneTimeTearDown(){
	rm -rf $TEMP
}

# copy code, but remove data which is not needed or we know it contains errors. ( like the dict )
setUp(){
	set +f
	cp -a * $TEMP/self/
        rm -R $TEMP/self/dict/*.dict
        rm $TEMP/self/*.sed
        rm -R $TEMP/self/test/expected/
        rm $TEMP/self/test/expected*
        rm -R $TEMP/self/.git
        rm -R $TEMP/self/test/stubs
        rm -R $TEMP/self/X/
        rm -Rf $TEMP/self/shunit2/
	set -f
}

# run over own code, assume zero errors.
testSelf(){
        $RUN -s -D $TEMP/self/ > $SPELLING_ERR
        count=$(cat $SPELLING_ERR | grep "^+" | wc -l)
        if [[ $count -eq 0 ]]
        then
          echo "*** * * * * * * * * * * * * * * * * * * ***"
          echo "*** hurray, no spelling errors detected ***"
          echo "*** * * * * * * * * * * * * * * * * * * ***"
        else
          echo "*** * * * * * * * * * * * * * * * * * * ***"
          echo "*** those spelling errors found...      ***"
          echo "*** * * * * * * * * * * * * * * * * * * ***"
          cat $SPELLING_ERR
        fi
	assertEquals "found some spelling-errors. :-( " $count 0
}


suite(){
	suite_addTest testSelf
}


# load shunit2
. shunit2/source/2.1/src/shunit2
