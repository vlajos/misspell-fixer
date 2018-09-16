# Misspell Fixer

==============

Utility to fix common misspellings, typos in source code. There are lots of typical misspellings in program code.
Typically they are more eye-catching in the living code but they can easily hide in comments, examples, samples, notes and documentation.
With this utility you can fix a large number of them very quickly.

In some environments the dependencies may cause some trouble. (Mac, Windows, older linux versions.)
In this case use misspell-fixer from a container.

## How to use it:

Pull the latest version:

    $ docker pull vlajos/misspell-fixer

And fix `targetdir`'s content:

    $ docker run -ti --rm -v targetdir:/work misspell-fixer -frunRVD .

#### Some other different use cases, examples:

General execution directly with docker:

    $ docker run -ti --rm -v targetdir:/work misspell-fixer arguments

`targetdir` becomes the current working directory in the container, so you can reference it as `.` in the arguments list.

You can also use the `dockered-fixer` wrapper from the source repository:

    $ dockered-fixer [any above arguments]

Or if your shell supports functions, you can define a function to make the command a little shorter:

    $ function misspell-fixer { docker run -ti --rm -v $(pwd):/work misspell-fixer "$@"; }

And fixing with the function:

    $ misspell-fixer [any above arguments]

Through the wrapper and the function it can access only the folders below the current working directory
as it is the only one passed to the container as a volume.

You can build the container locally, although this should not be really needed:

    $ docker build docker/ -t misspell-fixer

## General documentation: https://github.com/vlajos/misspell-fixer/blob/master/README.md

## Original source: https://github.com/vlajos/misspell-fixer
