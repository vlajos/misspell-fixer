# Misspell Fixer

[![Build Status](https://travis-ci.org/vlajos/misspell-fixer.svg?branch=master)](https://travis-ci.org/vlajos/misspell-fixer)
[![Coverage Status](https://img.shields.io/coveralls/vlajos/misspell-fixer.svg)](https://coveralls.io/r/vlajos/misspell-fixer?branch=master)
[![Circle CI Build Status](https://circleci.com/gh/vlajos/misspell-fixer.svg?style=svg)](https://circleci.com/gh/vlajos/misspell-fixer)
[![Issue Count](https://codeclimate.com/github/vlajos/misspell-fixer/badges/issue_count.svg)](https://codeclimate.com/github/vlajos/misspell-fixer)
[![Average time to resolve an issue](https://isitmaintained.com/badge/resolution/vlajos/misspell-fixer.svg)](https://isitmaintained.com/project/vlajos/misspell-fixer "Average time to resolve an issue")
[![Percentage of issues still open](https://isitmaintained.com/badge/open/vlajos/misspell-fixer.svg)](https://isitmaintained.com/project/vlajos/misspell-fixer "Percentage of issues still open")

Misspell Fixer is a command-line utility designed to automatically detect and correct common misspellings and typos in source code.
The tool addresses frequent spelling errors that commonly appear in program code, including those found in comments, documentation, examples, and code samples.
This utility enables rapid correction of numerous spelling errors across large codebases.

Please note that this utility does not modify file names. If a misspelled word appears in both a file's content and its name, only the content will be corrected; the file must be manually renamed.

Exercise extreme caution when applying corrections to public APIs, as spelling changes may introduce breaking changes for dependent systems.

Manual code review is always required after running this tool to ensure that corrections have not introduced unintended changes or broken functionality.

[Jump to Docker usage](#docker-usage)

### Synopsis
    
    misspell-fixer	[OPTION] target[s]

### Options and Arguments

`target[s]` can be any combination of files or directories.

#### Core Execution Options:

* `-r` Execute in real mode: Overwrites original files with corrected versions. Without this option, original files remain unmodified.
* `-n` Disable backup creation. By default, modified files are backed up with a `.$$.BAK` suffix.
* `-P n` Enable parallel processing using `n` worker processes. Example: `-P 4` processes files using 4 threads. Note: `-s` option is incompatible with parallel processing.
* `-f` Enable fast mode (equivalent to `-P4`).
* `-h` Display help information.

Performance considerations: The `-s`, `-v` options, or absence of `-n` or `-r` utilize slower internal processing loops. For optimal performance, use `-frn` without `-s` and `-v`.

#### Output Control Options:

* `-s` Display diff output showing proposed changes.
* `-v` Enable verbose mode: Display each file as it is processed (excludes prefiltering step).
* `-o` Enable progress mode: Display processing progress (prints a dot for each scanned file, comma for each fix iteration).
* `-d` Enable debug mode: Display detailed information about core logic steps.

#### Rule Set Options:

By default, approximately 100 carefully selected rules are enabled. Additional rule sets can be activated using the following options:

* `-u` Enable less conservative rules (requires more careful manual review). Adds approximately 10 rules.
* `-g` Enable British English to US English conversion rules. These address regional spelling differences rather than actual errors. Adds approximately 10 rules.
* `-R` Enable rare misspelling rules. Adds several hundred additional rules.
* `-V` Enable very rare misspelling rules, primarily sourced from Wikipedia articles. Adds over 4,000 rules.
* `-D` Enable rules derived from lintian.debian.org (git:ebac9a7). Adds approximately 2,300 rules.

Processing performance decreases with additional rule sets enabled, though modern grep implementations significantly mitigate this impact.

#### File Filtering Options:

* `-G` Respect `.gitignore` files (requires `git` command in PATH). This feature is experimental.
* `-N` Enable filename pattern filtering. Example: `-N '*.cpp' -N '*.h'` processes only C++ source files.
* `-i` Include version control system directories (process `.git`, `.svn`, `.hg`, `CVS` directories).
* `-b` Process binary and generated files (do not ignore `*.gif`, `*.jpg`, `*.jpeg`, `*.png`, `*.zip`, `*.svg`, `*.tiff`, `*.gz`, `*.bz2`, `*.xz`, `*.rar`, `*.po`, `*.pdf`, `*.woff`, `yarn.lock`, `package-lock.json`, `composer.lock`, `*.mo`, `*.mov`, `*.mp4`, `*.jar`).
* `-m` Disable file size filtering. Default behavior ignores files larger than 1MB (typically CSV files, minified JavaScript, etc.).

#### Whitelisting and Ignore Functionality:

Misspell Fixer automatically excludes issues matching patterns listed in `.misspell-fixer.ignore` or `.github/.misspell-fixer.ignore`.
The ignore file format follows the prefiltering temporary result format:

`^filename:line number:matched word`

* `-W` Append discovered issues to the ignore file instead of applying fixes based on other settings.
* `-w filename` Specify a custom ignore file path (overrides default ignore file locations).

The ignore file functions as a grep exclusion list, applied after the prefiltering step.
This enables exclusion of specific prefixes or entire files.
To exclude complete files, use only the filename:

`^filename`

To exclude an entire directory:

`^directory`

Path matching is based on the current invocation context.
Accessing the same target via different paths from the same working directory may not apply
whitelist entries consistently. For example, in directory `x`, whitelist entries created with
target `.` will not apply to target `../x`, despite referencing identical content.
Manual editing of the whitelist file can work around this limitation.

### Exit Codes

The script returns exit code `0` when no typos or errors are found or fixed.

* `0` No typos detected
* `1-5` Typos found and processed. The return value indicates the number of processing iterations executed
* `10` Help information successfully displayed
* `11` Whitelist file successfully saved
* `100+` Parameter errors (invalid, missing, or conflicting options)

### Usage Examples

#### Basic Usage

Check for typos without making changes (minimal output):
Return value can be used to detect whether it found any typos or not.

    $ misspell-fixer target

Apply fixes with verbose file reporting:

    $ misspell-fixer -rv target

Display proposed changes without modifying files:

    $ misspell-fixer -sv target

Display changes with progress indicators and apply fixes:

    $ misspell-fixer -rsv target

#### Performance-Optimized Usage

Maximum performance mode (fast processing, no backups):

    $ misspell-fixer -frn target

Maximum performance with all rule sets enabled:

    $ misspell-fixer -frunRVD target

### Data Sources

This tool incorporates misspelling databases from the following sources:

* https://en.wikipedia.org/wiki/Commonly_misspelled_words
* https://github.com/neleai/stylepp
* https://en.wikipedia.org/wiki/Wikipedia:Lists_of_common_misspellings/For_machines
* https://anonscm.debian.org/git/lintian/lintian.git/tree/data/spelling/corrections
* http://www.how-do-you-spell.com/
* http://www.wrongspelled.com/

### Docker Usage

For environments where dependency management presents challenges (macOS, Windows, legacy Linux distributions),
Misspell Fixer is available as a Docker container image.

Pull the latest container image:

    $ docker pull vlajos/misspell-fixer

Process the contents of `targetdir`:

    $ docker run -ti --rm -v targetdir:/work vlajos/misspell-fixer -frunRVD .

#### Alternative Docker Usage Patterns:

Standard Docker execution:

    $ docker run -ti --rm -v targetdir:/work vlajos/misspell-fixer [arguments]

The `targetdir` becomes the working directory within the container and can be referenced as `.` in the arguments.

Using the included `dockered-fixer` wrapper script:

    $ dockered-fixer [arguments]

Creating a shell function for convenience (bash/zsh):

    $ function misspell-fixer { docker run -ti --rm -v $(pwd):/work vlajos/misspell-fixer "$@"; }

Using the shell function:

    $ misspell-fixer [arguments]

Both the wrapper script and shell function can only access directories below the current working directory, as only the current directory is mounted as a volume in the container.

To build the container locally:

    $ docker build . -t misspell-fixer

### GitHub Actions Integration

A [GitHub Action](https://github.com/sobolevn/misspell-fixer-action) is available for integrating Misspell Fixer into CI/CD workflows.
The action supports automatic pull request creation with proposed fixes.

### Dependencies

Misspell Fixer is implemented as a bash script that coordinates between established Unix utilities (mainly `grep` and `sed`.
The core functionality leverages `grep`'s `-F` flag for efficient parallel pattern matching using the [Aho–Corasick algorithm](https://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_algorithm), combined with `sed`'s targeted line modifications.
Proper `-w` (whole word) support requires grep version 2.28 or later.

#### Required Dependencies:

* bash
* find
* sed
* grep (version 2.28+ recommended)
* diff
* sort
* tee
* cut
* rm, cp, mv
* xargs

#### Optional Dependencies:

* git (required for `.gitignore` file support)
* ugrep (provides significant performance improvements when available)

### Authors

* Veres Lajos
* ka7

### Project Repository

https://github.com/vlajos/misspell-fixer

This project is open source and freely available for use.
