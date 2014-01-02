#!/bin/bash

set -f

export opt_debug=0
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

export opt_name_filter=''

function warning {
	echo "misspell_fixer: $@">&2
}
function verbose {
	if [[ $opt_verbose = 1 ]]
	then
		warning "$@"
	fi
}

while getopts ":dvrfsinuhN:" opt; do
	case $opt in
		d)
			warning "-d Enabling debug mode"
			opt_debug=1
		;;
		v)
			warning "-v Enabling verbose mode"
			opt_verbose=1
		;;
		r)
			warning "-r Enabling real run. overwrite original files!"
			opt_real_run=1
		;;
		f)
			warning "-f Enabling fast mode"
			opt_fast_mode=1
		;;
		s)
			warning "-s Enabling showing of diffs"
			opt_show_diff=1
		;;
		i)
			warning "-i Disable scm dir ignoring"
			opt_ignore_scm_dirs=1
			cmd_part_ignore=''
		;;
		n)
			warning "-n Disabling backups"
			opt_backup=0
		;;
		u)
			warning "-u Enabling unsafe rules"
			cmd_part_rules="$cmd_part_rules -f $rules_not_so_safe"
		;;
		N)
			warning "-N Enabling name filter: $OPTARG"
			if [ -n "$opt_name_filter" ]; then
				opt_name_filter="$opt_name_filter -or -name $OPTARG"
			else
				opt_name_filter="-name $OPTARG"
			fi
		;;
		h)
			cat $(dirname $0)/README.md
			exit
		;;
		\?)
			warning "Invalid option: -$OPTARG"
			exit
		;;
		:)
			warning "Option -$OPTARG requires an argument."
			exit
		;;
	esac
done

shift $((OPTIND-1))

if [[ "$@" = "" ]]
then
	warning "Not enought arguments. (target directory not found) => Exiting"
	exit
fi
warning "Target directories: $@"

if [[ $opt_fast_mode = 1 ]]
then
	if [[ $opt_real_run = 0 ]]
	then
		warning "Fast mode works only with real run. Real run is not switched on. => Exiting"
		exit
	fi
	if [[ $opt_backup = 1 ]]
	then
		warning "Fast mode cannot make backups. Backups are enabled. => Exiting"
		exit
	fi
	if [[ $opt_show_diff = 1 ]]
	then
		warning "Fast mode cannot show diffs. Showing diffs is turned on. => Exiting"
		exit
	fi
	if [[ $opt_verbose = 1 ]]
	then
		warning "Fast mode cannot be verbose. Verbose mode is turned on. => Exiting"
		exit
	fi

	warning "Starting script"
	if [[ $opt_debug = 1 ]]
	then
		set -x
	fi
	find "$@"\
		-type f\
		$cmd_part_ignore \
		-and \( $opt_name_filter \) \
		-exec sed -i -b $cmd_part_rules {} +
	set +x
	warning "Done."
	exit;
fi

function loop_core {
	if [[ $opt_debug = 1 ]]
	then
		set -x
	fi
	verbose "actual file: $1"
	tmpfile=$1.$$
	verbose "temp file: $tmpfile"
	sed $cmd_part_rules "$1" >"$tmpfile"
	IFS=''
	diff=$(diff -uwb $1 $tmpfile)
	if [[ $? = 0 ]]
	then
		verbose "nothing changed"
		rm $tmpfile
	else
		verbose "misspells are fixed!"
		if [[ $opt_show_diff = 1 ]]
		then
			echo $diff
		fi
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
export -f loop_core verbose warning

if [[ $opt_debug = 1 ]]
then
	set -x
fi
warning "Starting script"
find "$@"\
	-type f\
	$cmd_part_ignore \
	-and \( $opt_name_filter \) \
	-exec bash -c 'loop_core "$0"' {} \;
warning "Done."
