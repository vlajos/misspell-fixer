# Example watch control file for uscan
# Rename this file to "watch" and then you can run the "uscan" command
# to check for upstream updates and more.
# See uscan(1) for format

# Compulsory line, this is a version 4 file
version=4

# PGP signature mangle, so foo.tar.gz has foo.tar.gz.sig
#opts="pgpsigurlmangle=s%$%.sig%"

# GitHub hosted projects
#opts="filenamemangle=s%(?:.*?)?v?(\d[\d.]*)\.tar\.gz%<project>-$1.tar.gz%" \
#   https://github.com/<user>/misspell-fixer/tags \
#   (?:.*?/)?v?(\d[\d.]*)\.tar\.gz debian uupdate

# Direct Git
# opts="mode=git" https://git.example.com/misspell-fixer.git \
#   refs/tags/v([\d\.]+) debian uupdate
