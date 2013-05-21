#!/bin/bash

rules=$(echo $0|sed 's/sh$/sed/')

find .\
	-type f\
	! -wholename '*.git*'\
	! -wholename '*.svn*'\
	-print0 |\
xargs -0 sed -i -f $rules
