#!/bin/bash

#cwd, wait

export opt_verbose=0
export opt_show_diff=0
export opt_fast_mode=0
export opt_real_run=0
export opt_backup=1
export opt_ignore_scm_dirs=1

rules_safe=$(echo $0|sed 's/\.sh$/_safe.sed/')
rules_not_so_safe=$(echo $0|sed 's/\.sh$/_not_so_safe.sed/')
export cmd_part_rules="-f $rules_safe"

export cmd_part_ignore=" ! -wholename *.git* ! -wholename *.svn* "

function warning {
	echo "misspell_fixer: $@">&2
}

while getopts ":vrfdinuh" opt; do
	case $opt in
		v)
			warning "enabling verbose mode"
			opt_verbose=1
		;;
		r)
			warning "enabling real run. overwrite original files!"
			opt_real_run=1
		;;
		f)
			warning "enabling fast mode"
			opt_fast_mode=1
		;;
		d)
			warning "enabling showing of diffs"
			opt_show_diff=1
		;;
		d)
			warning "disable scm dir ignoring"
			opt_ignore_scm_dirs=1
			cmd_part_ignore=''
		;;
		n)
			warning "disabling backups"
			opt_backup=0
		;;
		u)
			warning "enabling unsafe rules"
			cmd_part_rules="$cmd_part_rules -f $rules_not_so_safe"
		;;
		h)
			cat $(dirname $0)/README.md
			exit
		;;
		\?)
			warning "Invalid option: -$OPTARG"
			exit
		;;
	esac
done

shift $((OPTIND-1))

if [[ "$@" = "" ]]
then
	warning "not enought arguments. (target directory not found) => Exiting"
	exit
fi
warning "target directories: $@"

if [[ $opt_fast_mode = 1 ]]
then
	if [[ $opt_real_run = 0 ]]
	then
		warning "fast mode works only with real run. Real run is not switched on. => Exiting"
		exit
	fi
	if [[ $opt_backup = 1 ]]
	then
		warning "fast mode cannot make backups. Backups are enabled. => Exiting"
		exit
	fi
	if [[ $opt_show_diff = 1 ]]
	then
		warning "fast mode cannot show diffs. Showing diffs is turned on. => Exiting"
		exit
	fi

	warning "starting script"
	if [[ $opt_verbose = 1 ]]
	then
		set -x
	fi
	find "$@"\
		-type f\
		$cmd_part_ignore \
		-exec sed -i $cmd_part_rules {} +
	set +x
	warning "done"
	exit;
fi

function loop_core {
	if [[ $opt_verbose = 1 ]]
	then
		set -x
	fi
	tmpfile=$1.$$
	sed $cmd_part_rules "$1" >"$tmpfile"
	IFS=''
	samefile=0
	diff=$(diff -uwb $1 $tmpfile && samefile=1)
	if [[ $opt_show_diff = 1 ]]
	then
		echo $diff
	fi
	if [[ $samefile = 1 ]]
	then
		rm $tmpfile
	else
		if [[ $opt_real_run = 1 ]]
		then
			if [[ $opt_backup = 1 ]]
			then
				mv $1 $tmpfile.BAK
			fi
			mv $tmpfile $1
		else
			rm $tmpfile
		fi
	fi
}
export -f loop_core

if [[ $opt_verbose = 1 ]]
then
	set -x
fi
find "$@"\
	-type f\
	$cmd_part_ignore \
	-exec bash -c 'loop_core "$0"' {} \;
