# Misspell Fixer

[![Build Status](https://travis-ci.org/vlajos/misspell-fixer.svg?branch=master)](https://travis-ci.org/vlajos/misspell-fixer)
[![Coverage Status](https://img.shields.io/coveralls/vlajos/misspell-fixer.svg)](https://coveralls.io/r/vlajos/misspell-fixer?branch=master)
[![Circle CI Build Status](https://circleci.com/gh/vlajos/misspell-fixer.svg?style=svg)](https://circleci.com/gh/vlajos/misspell-fixer)
[![Issue Count](https://codeclimate.com/github/vlajos/misspell-fixer/badges/issue_count.svg)](https://codeclimate.com/github/vlajos/misspell-fixer)
[![Average time to resolve an issue](https://isitmaintained.com/badge/resolution/vlajos/misspell-fixer.svg)](https://isitmaintained.com/project/vlajos/misspell-fixer "Average time to resolve an issue")
[![Percentage of issues still open](https://isitmaintained.com/badge/open/vlajos/misspell-fixer.svg)](https://isitmaintained.com/project/vlajos/misspell-fixer "Percentage of issues still open")

Utility to fix common misspellings, typos in source code. There are lots of typical misspellings in program code.
Typically they are more eye-catching in the living code but they can easily hide in comments, examples, samples, notes and documentation.
With this utility you can fix a large number of them very quickly.

Be aware that the utility does not check or fix file names. It could easily happen that a misspelled word is fixed in a file name in a program's code, but
the file itself will not be renamed by this utility.

It is also important to be very careful when fixing public APIs!

A manual review is always needed to verify that nothing has been broken.

[Jump to docker notes](#with-docker)

### Synopsis
    
    misspell-fixer	[OPTION] target[s]

### Options, Arguments

`target[s]` can be any file[s] or directory/ies.

Main options:

* `-r` Real run mode: Overwrites the original files with the fixed one. Without this option the originals will be untouched.
* `-n` Disable backups. (By default the modified files' originals will be saved with the `.$$.BAK` suffix.)
* `-P n` Enable processing on `n` forks. For example: `-P 4` processes the files in 4 threads. (`-s` option is not supported)
* `-f` Fast mode. (Equivalent with `-P4`)
* `-h` Help.

Performance note: `-s`, `-v` or the lack of `-n` or `-r` use a slower processing internal loop. So usually `-frn` without `-s` and `-v` are the highest performing
combination.

Output control options:

* `-s` Shows diffs of changes.
* `-v` Verbose mode: shows the iterated files. (Without the prefiltering step)
* `-o` Verbose mode: shows progress (prints a dot for each file scanned, a comma for each file fix iteration/file.)
* `-d` Debug mode: shows all steps of the core logic.

By default only a subset of rules are enabled (around 100). You can enable more rules with the following options:

* `-u` Enable less safe rules. (Manual review's importance is more significant...) (Around ten rules.)
* `-g` Enable rules to convert British English to US English. (These rules aren't exactly typos but sometimes they can be useful.) (Around ten rules.)
* `-R` Enable rare rules. (Few hundred rules.)
* `-V` Enable very rare rules. (Mostly from the wikipedia article.) (More than four thousand rules.)
* `-D` Enable rules based on lintian.debian.org  ( git:ebac9a7, ~2300 )

The processing speed decreases as you activate more rules. But with newer greps this is much less significant.

File filtering options:

* `-G` Respect `.gitignore` files. (Requires executable `git` command.) (experimental)
* `-N` Enable file name filtering. For example: `-N '*.cpp' -N '*.h'`
* `-i` Walk through source code management system's internal directories. (do not ignore `.git`, `.svn`, `.hg`, `CVS`)
* `-b` Process binary, generated files. (do not ignore `*.gif`, `*.jpg`, `*.jpeg`, `*.png`, `*.zip`, `*.gz`, `*.bz2`, `*.xz`, `*.rar`, `*.po`, `*.pdf`, `*.woff`, `yarn.lock`, `package-lock.json`, `composer.lock`, `*.mo`, `*.mov`, `*.mp4`, `*.jar`)
* `-m` Disable file size checks. Default is to ignore files > 1MB. (usually csv, compressed JS, ..)

Whitelisting files/entries:

Misspell-fixer automatically ignores the issues matching to the patterns listed in `.misspell-fixer.ignore` or `.github/.misspell-fixer.ignore`.
The format of this file follows the prefiltering's temporary result format:

`^filename:line number:matched word`

* `-W` can be used to append the found issues instead of fixing them based on the other settings.
* `-w filename` can be used to override the ignore file's name.

The ignore file is interpreted as a `grep` exclusion list.
It is applied after the prefiltering step as a set of grep expression.
So it is possible to exclude any prefixes or more specifically whole files with keeping only their file names:

`^filename`

Or a directory:

`^directory`

The entries are listed/matched with the paths based on the current invocation. Reaching the same target with different path from
the same working directory will not apply the whitelisted entries generated from the other invocation.
In directory `x` the whitelist entries generated with target `.` will not be applied for target `../x`, although they are the same.
There is a workaround for this with manually editing the whitelist to your needs.
(Patches are welcome for a more general solution...)

### Return values

Generally the script tries to return with `0` if there were no typos or errors found/fixed.

* `0` No typos found,
* `1-5` Typos found. The return value shows the number of iterations executed.
* `10` Help successfully printed.
* `11` Whitelist successfully saved.
* `100-` Parameter errors. (invalid, missing, conflicting)


### Sample usage

Without arguments, the script will not change anything and its output is minimal.
Its return value can be used to detect whether it found any typos or not.

    $ misspell-fixer target

Fixing the files with displaying each fixed file:

    $ misspell-fixer -rv target

Showing only the diffs without modifying the originals:

    $ misspell-fixer -sv target

Showing the diffs with progress and fixing the found typos:

    $ misspell-fixer -rsv target

Fast mode example, no backups: (highest performance)

    $ misspell-fixer -frn target

The previous with all rules enabled:

    $ misspell-fixer -frunRVD target

It is based on the following sources for common misspellings:

* https://en.wikipedia.org/wiki/Commonly_misspelled_words
* https://github.com/neleai/stylepp
* https://en.wikipedia.org/wiki/Wikipedia:Lists_of_common_misspellings/For_machines
* https://anonscm.debian.org/git/lintian/lintian.git/tree/data/spelling/corrections
* http://www.how-do-you-spell.com/
* http://www.wrongspelled.com/

### With Docker

In some environments the dependencies may cause some trouble. (Mac, Windows, older linux versions.)
In this case, you can use misspell-fixer as a docker container image.

Pull the latest version:

    $ docker pull vlajos/misspell-fixer

And fix `targetdir`'s content:

    $ docker run -ti --rm -v targetdir:/work vlajos/misspell-fixer -frunRVD .

#### Some other different use cases, examples:

General execution directly with docker:

    $ docker run -ti --rm -v targetdir:/work vlajos/misspell-fixer [arguments]

`targetdir` becomes the current working directory in the container, so you can reference it as `.` in the arguments list.

You can also use the `dockered-fixer` wrapper from the source repository:

    $ dockered-fixer [arguments]

In case your shell supports functions, you can define a function to make the command a little shorter:

    $ function misspell-fixer { docker run -ti --rm -v $(pwd):/work vlajos/misspell-fixer "$@"; }

And fixing with the function:

    $ misspell-fixer [arguments]

Through the wrapper and the function it can access only the folders below the current working directory
as it is the only one passed to the container as a volume.

You can build the container locally, although this should not be really needed:

    $ docker build . -t misspell-fixer

### With GitHub Actions

There's a [GitHub Action](https://github.com/sobolevn/misspell-fixer-action) to run `misspell-fixer` as well.
It even allows to automatically send PRs with the fixes.

### Dependencies - "On the shoulders of giants"

The script itself is just a misspelling database and some glue in `bash` between `grep` and `sed`.
`grep`'s `-F` combined with `sed`'s line targeting makes the script quite efficient.
`-F` enables parallel pattern matching with the [Aho–Corasick algorithm](https://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_algorithm) .
Unfortunately only the newer (2.28+) versions of grep supports `-w` properly.

A little more comprehensive list:

* bash
* find
* sed
* grep
* diff
* sort
* tee
* cut
* rm, cp, mv
* xargs
* git (for respecting .gitignore files)

### Authors

* Veres Lajos
* ka7

### Original source

https://github.com/vlajos/misspell-fixer

Feel free to use!
