# Misspell Fixer

[![Build Status](https://travis-ci.org/vlajos/misspell_fixer.svg?branch=master)](https://travis-ci.org/vlajos/misspell_fixer)
[![Coverage Status](https://img.shields.io/coveralls/vlajos/misspell_fixer.svg)](https://coveralls.io/r/vlajos/misspell_fixer?branch=master)
[![Circle CI Build Status](https://circleci.com/gh/vlajos/misspell_fixer.svg?style=shield&circle-token=d5d85ed2985b507b547a98e2ace8c21a75395cc2)](https://circleci.com/gh/vlajos/misspell_fixer)
[![Gratipay](https://img.shields.io/gratipay/JSFiddle.svg)](https://gratipay.com/~vlajos/)

==============

Utility to fix common misspellings, typos in source codes. There are lots of typical misspellings in program codes.
Typically they are more eye-catching in the living code but they can easily hide in comments, examples, samples, notes and documentations.
With this utility you can fix a large number of them very quickly.

Be aware that the utility does not check or fix file names. It can easily happen that a misspelled word is fixed in a file name in a program's code, but
the file itself will not be renamed by this utility.

And also important to note to be extra careful when fixing public APIs!

A manual review is always needed to verify that nothing has been broken.

### Synopsis
    
    misspell_fixer	[OPTION] target

### Options, Arguments

`target` can be any file or directory.

* `-d` Debug mode: shows the core logics all steps
* `-v` Verbose mode: shows the iterated files
* `-r` Real run mode: Overwrites the original files with the fixed one. Without this option the originals will be untouched.
* `-f` Fast mode: Faster mode with limited options. (`-v`, `-s` options are not supported) Works only with real run mode `-r`. This mode cannot make backups. (`-n` is also needed)
* `-s` Shows diffs of changes.
* `-i` Walk through source code management system's internal directories. (don't ignore `*.svn*`, `*.git*`)
* `-b` Process binary files. (don't ignore `*.gif`, `*.jpg`, `*.png`, `*.zip`, `*.gz`, `*.bz2`, `*.rar`)
* `-n` Disabling backups. (By default the modified files' originals will be saved with the `.$$.BAK` suffix.)
* `-N` Enable file name filtering. For example: `-N '*.cpp' -N '*.h'`
* `-P` Enable parallelism. For example: `-P 4` processes the files in 4 thread. (Supported only in fast mode.)
* `-h` Help. Displays this page.

By default only a subset of rules are enabled (around 100). You can enable more rules with the following options:

* `-u` Enabling less safe rules. (Manual revise's need will be more probable.) (Around ten rules.)
* `-g` Enabling rules to convert British English to US English. (These rules aren't exactly typos but sometimes they can be useful.) (Around ten rules.)
* `-R` Enabling rare rules. (Few hundred rules.)
* `-V` Enabling very rare rules. (Mostly from the wikipedia article.) (More than four thousand rules.)

The processing speed decreases as you activate more rules.

### Sample usages

By default nothing important will happen

    $ misspell_fixer.sh target

What you can track with -v

    $ misspell_fixer.sh -v target

A real usage:

    $ misspell_fixer.sh -r -v target

Show only the diff, don't modify the files:

    $ misspell_fixer.sh -s -v target

Show everything and fix the files:

    $ misspell_fixer.sh -r -s -v target

Fast mode example:

    $ misspell_fixer.sh -r -f -n target

Fast mode example with mass processing:

    $ misspell_fixer.sh -frnR -P4 target

It is based on the following sources for common misspellings:

* http://www.how-do-you-spell.com/
* http://en.wikipedia.org/wiki/Commonly_misspelled_words
* http://www.wrongspelled.com/
* https://github.com/neleai/stylepp
* http://en.wikipedia.org/wiki/Wikipedia:Lists_of_common_misspellings/For_machines

### Dependencies

* bash
* find
* sed
* diff
* xargs (for parallelism)

### Author

Veres Lajos

### Original source

https://github.com/vlajos/misspell_fixer

Feel free to use!
