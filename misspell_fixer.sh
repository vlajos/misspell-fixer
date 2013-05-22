#!/bin/bash

rules_safe=$(echo $0|sed 's/sh$/_safe.sed/')
rules_not_so_safe=$(echo $0|sed 's/sh$/_not_so_safe.sed/')

find .\
	-type f\
	! -wholename '*.git*'\
	! -wholename '*.svn*'\
	-print0 |\
xargs -0 sed -i -f $rules_safe -f $rules_not_so_safe
