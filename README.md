Misspell Fixer
==============

Utility to fix common misspellings in source codes.

It is based on the next common misspellings sources:
* http://www.how-do-you-spell.com/
* http://en.wikipedia.org/wiki/Commonly_misspelled_words
* http://www.wrongspelled.com/

Depends on the next unix tools:
* find
* sed

It works in the current work directory.
Actually it doesnt support extra parameters.

WARNING: It overwrites original files! Thus make a backup before running it!

Sample usage:
    cd /some/directory/which/contains/text/files
    # make a backup for safety
    misspell_fixer.sh

