#!/usr/bin/env bash

function warning {
	echo "misspell_fixer: $*">&2
}

function verbose {
	if [[ $opt_verbose = 1 ]]
	then
		warning "$@"
	fi
}

function init_variables {
	set -f

	export LC_CTYPE=C
	export LANG=C

	export opt_debug=0
	export opt_verbose=0
	export opt_show_diff=0
	export opt_fast_mode=0
	export opt_real_run=0
	export opt_backup=1
	export opt_parallelism=0
	export opt_dots=0
	
	rules_safe0=${BASH_SOURCE/%.sh/_safe.0.sed}
	rules_safe1=${BASH_SOURCE/%.sh/_safe.1.sed}
	rules_safe2=${BASH_SOURCE/%.sh/_safe.2.sed}
	rules_safe3=${BASH_SOURCE/%.sh/_safe.3.sed}
	rules_not_so_safe=${BASH_SOURCE/%.sh/_not_so_safe.sed}
	rules_gb_to_us=${BASH_SOURCE/%.sh/_gb_to_us.sed}
	export cmd_part_rules="-f $rules_safe0"

	export cmd_part_ignore_scm=" ! -wholename *.git* ! -wholename *.svn* ! -wholename *.hg* "
	export cmd_part_ignore_bin=" ! -iwholename *.gif ! -iwholename *.jpg ! -iwholename *.png ! -iwholename *.zip ! -iwholename *.gz ! -iwholename *.bz2 ! -iwholename *.rar ! -iwholename *.po "
	export cmd_part_ignore

	export opt_name_filter=''
        export cmd_size=" -and ( -size 1M ) "  # find will ignore files > 1MB

	export directories
}

function parse_basic_options {
	local OPTIND
	while getopts ":dvorfsibnRVDmughN:P:" opt; do
		case $opt in
			d)
				warning "-d Enabling debug mode."
				opt_debug=1
			;;
			v)
				warning "-v Enabling verbose mode."
				opt_verbose=1
			;;
			o)
				warning "-o print dots for each file processed."
				opt_dots=1
			;;
			r)
				warning "-r Enabling real run. Overwrite original files!"
				opt_real_run=1
			;;
			f)
				warning "-f Enabling fast mode."
				opt_fast_mode=1
			;;
			s)
				warning "-s Enabling showing of diffs."
				opt_show_diff=1
			;;
			i)
				warning "-i Disable scm dir ignoring."
				cmd_part_ignore_scm=''
			;;
			b)
				warning "-i Disable binary ignoring."
				cmd_part_ignore_bin=''
			;;
			n)
				warning "-n Disabling backups."
				opt_backup=0
			;;
			u)
				warning "-u Enabling unsafe rules."
				cmd_part_rules="$cmd_part_rules -f $rules_not_so_safe"
			;;
			R)
				warning "-R Enabling rare rules."
				cmd_part_rules="$cmd_part_rules -f $rules_safe1"
			;;
			V)
				warning "-V Enabling very-rare rules."
				cmd_part_rules="$cmd_part_rules -f $rules_safe2"
			;;
			D)
				warning "-D Enabling rules from lintian.debian.org / spelling."
				cmd_part_rules="$cmd_part_rules -f $rules_safe3"
			;;
			m)
				warning "-m disable max-size check. default is to ignore files > 1MB"
				cmd_size=" "
			;;
			g)
				warning "-g Enabling GB to US rules."
				cmd_part_rules="$cmd_part_rules -f $rules_gb_to_us"
			;;
			N)
				warning "-N Enabling name filter: $OPTARG"
				if [ -n "$opt_name_filter" ]; then
					opt_name_filter="$opt_name_filter -or -name $OPTARG"
				else
					opt_name_filter="-name $OPTARG"
				fi
			;;
			P)
				warning "-P Enabling parallelism: $OPTARG"
				opt_parallelism=$OPTARG
			;;
			h)
                                d="dirname ${BASH_SOURCE}"
				cat "$($d)"/README.md
				return 1
			;;
			\?)
				warning "Invalid option: -$OPTARG"
				return 1
			;;
			:)
				warning "Option -$OPTARG requires an argument."
				return 1
			;;
		esac
	done
	
	if [ -z "$opt_name_filter" ]; then
		opt_name_filter='-true'
	fi
	
	shift $((OPTIND-1))
	
	if [[ "$@" = "" ]]
	then
		warning "Not enough arguments. (target directory not found) => Exiting."
		return 1
	fi

	directories="$*"
	cmd_part_ignore="$cmd_part_ignore_scm $cmd_part_ignore_bin"
	warning "Target directories: $directories"

	return 0
}

function main_work {
	if [[ $opt_fast_mode = 1 ]]
	then
		main_work_fast "$1"
		return $?
	else
		main_work_normal "$1"
		return $?
	fi
}

function main_work_fast {
	if [[ $opt_real_run = 0 ]]
	then
		warning "Fast mode works only with real run. Real run is not switched on. => Exiting."
		return 1
	fi
	if [[ $opt_backup = 1 ]]
	then
		warning "Fast mode cannot make backups. Backups are enabled. => Exiting."
		return 1
	fi
	if [[ $opt_show_diff = 1 ]]
	then
		warning "Fast mode cannot show diffs. Showing diffs is turned on. => Exiting."
		return 1
	fi
	if [[ $opt_verbose = 1 ]]
	then
		warning "Fast mode cannot be verbose. Verbose mode is turned on. => Exiting."
		return 1
	fi

	warning "Starting script"
	if [[ $opt_debug = 1 ]]
	then
		set -x
	fi
	if [[ $opt_parallelism = 0 ]]
	then
		find "$directories" -type f $cmd_part_ignore -and \( $opt_name_filter \) $cmd_size -exec sed -i -b $cmd_part_rules {} +
	else
		find "$directories" -type f $cmd_part_ignore -and \( $opt_name_filter \) $cmd_size -print0|xargs -0 -P $opt_parallelism -n 100 sed -i -b $cmd_part_rules
	fi
	warning "Done."
	return 0
}

function main_work_normal_one {
	verbose "actual file: $1"
	tmpfile=$1.$$
	verbose "temp file: $tmpfile"
	cp -a "$1" "$tmpfile"
	sed -b $cmd_part_rules "$1" >"$tmpfile"
	diff=$(diff -uwb "$1" "$tmpfile")
	if [[ $? = 0 ]]
	then
		verbose "nothing changed"
		rm "$tmpfile"
	else
		verbose "misspellings are fixed!"
		if [[ $opt_show_diff = 1 ]]
		then
			echo "$diff"
		fi
		if [[ $opt_real_run = 1 ]]
		then
			if [[ $opt_backup = 1 ]]
			then
				mv "$1" "$tmpfile.BAK"
			fi
			mv "$tmpfile" "$1"
		else
			rm "$tmpfile"
		fi
	fi
}

function main_work_normal {
	if [[ $opt_debug = 1 ]]
	then
		set -x
	fi
	warning "Starting script"
	find "$directories"\
		-type f\
		$cmd_part_ignore \
		-and \( $opt_name_filter \) \
                $cmd_size \
		-print0 |\
		while IFS="" read -r -d "" file
		do
                        if [[ $opt_dots = 1 ]]
                        then 
                          echo -n "." >&2;
                        fi
			main_work_normal_one "$file"
		done
	warning "Done."
	return 0
}

init_variables

parse_basic_options "$@"
retval=$?

if [[ $retval == 0 ]]
then
	main_work "$directories"
	retval=$?
fi

if [[ "$SHUNIT_VERSION" = "" ]]
then
	exit $retval
else
	return $retval
fi
