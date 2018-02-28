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
	export opt_real_run=0
	export opt_backup=1
	export opt_dots=0
	
	rules_safe0=${BASH_SOURCE/%.sh/_safe.0.sed}
	rules_safe1=${BASH_SOURCE/%.sh/_safe.1.sed}
	rules_safe2=${BASH_SOURCE/%.sh/_safe.2.sed}
	rules_safe3=${BASH_SOURCE/%.sh/_safe.3.sed}
	rules_not_so_safe=${BASH_SOURCE/%.sh/_not_so_safe.sed}
	rules_gb_to_us=${BASH_SOURCE/%.sh/_gb_to_us.sed}
	export cmd_part_rules="-f $rules_safe0"

	export cmd_part_ignore_scm=" ! -wholename *.git* ! -wholename *.svn* ! -wholename *.hg* "
	export cmd_part_ignore_bin=" ! -iwholename *.gif ! -iwholename *.jpg ! -iwholename *.png ! -iwholename *.zip ! -iwholename *.gz ! -iwholename *.bz2 ! -iwholename *.xz ! -iwholename *.rar ! -iwholename *.po ! -iwholename *.pdf ! -iwholename *.woff ! -iwholename *yarn.lock  ! -iwholename *package-lock.json  ! -iwholename *composer.lock  ! -iwholename *.mo "
	export cmd_part_ignore

	export cmd_part_parallelism

	export loop_function=loop_main_replace

	export opt_name_filter=''
	export cmd_size=" -and ( -size 1M ) "  # find will ignore files > 1MB

	export directories

	export tmpfile=.misspell_fixer.$$
}

function parse_basic_options {
	local OPTIND
	while getopts ":dvorfsibnRVDmughN:P:" opt; do
		case $opt in
			d)
				warning "-d Enable debug mode."
				opt_debug=1
			;;
			v)
				warning "-v Enable verbose mode."
				opt_verbose=1
			;;
			o)
				warning "-o Print dots for each file scanned, comma for each file fix iteration/file."
				opt_dots=1
			;;
			r)
				warning "-r Enable real run. Overwrite original files!"
				opt_real_run=1
			;;
			f)
				warning "-f Enable fast mode. (Equivalent with -P4)"
				cmd_part_parallelism="-P 4"
			;;
			s)
				warning "-s Enable showing of diffs."
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
				warning "-n Disable backups."
				opt_backup=0
			;;
			u)
				warning "-u Enable unsafe rules."
				cmd_part_rules="$cmd_part_rules -f $rules_not_so_safe"
			;;
			R)
				warning "-R Enable rare rules."
				cmd_part_rules="$cmd_part_rules -f $rules_safe1"
			;;
			V)
				warning "-V Enable very-rare rules."
				cmd_part_rules="$cmd_part_rules -f $rules_safe2"
			;;
			D)
				warning "-D Enable rules from lintian.debian.org / spelling."
				cmd_part_rules="$cmd_part_rules -f $rules_safe3"
			;;
			m)
				warning "-m Disable max-size check. Default is to ignore files > 1MB."
				cmd_size=" "
			;;
			g)
				warning "-g Enable GB to US rules."
				cmd_part_rules="$cmd_part_rules -f $rules_gb_to_us"
			;;
			N)
				warning "-N Enable name filter: $OPTARG"
				if [ -n "$opt_name_filter" ]; then
					opt_name_filter="$opt_name_filter -or -name $OPTARG"
				else
					opt_name_filter="-name $OPTARG"
				fi
			;;
			P)
				warning "-P Enable parallelism: $OPTARG"
				cmd_part_parallelism="-P $OPTARG"
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
	cmd_part_ignore=" ! -iwholename *$tmpfile* $cmd_part_ignore_scm $cmd_part_ignore_bin"
	warning "Target directories: $directories"

	return 0
}

function process_parameter_rules {
	if [[ $opt_show_diff = 1 ]]
	then
		main_loop=loop_decorated_mode
	fi
	if [[ $opt_backup = 1 ]]
	then
		main_loop=loop_decorated_mode
	fi
	if [[ $opt_real_run = 0 ]]
	then
		main_loop=loop_decorated_mode
	fi
	if [[ -z $cmd_part_parallelism ]]
	then
		return 0
	fi
	if [[ $opt_show_diff = 1 ]]
	then
		warning "Parallel mode cannot show diffs. Showing diffs is turned on. => Exiting."
		return 1
	fi
	if [[ $opt_verbose = 1 ]]
	then
		warning "Parallel mode cannot be verbose. Verbose mode is turned on. => Exiting."
		return 1
	fi
}

function preprocess_rules {
	cat $(echo $cmd_part_rules|sed -e 's/-f//g')|grep -v 'bin/sed' > $tmpfile.prep.allsedrules
	grep    '\\b' $tmpfile.prep.allsedrules|sed -e 's/^s\///g' -e 's/\/.*g//g' -e 's/\\b//g'	>$tmpfile.prep.grep.rules.w
	grep -v '\\b' $tmpfile.prep.allsedrules|sed -e 's/^s\///g' -e 's/\/.*g//g'			>$tmpfile.prep.grep.rules
}

function prepare_prefilter_input_from_find {
	find "$directories" -type f $cmd_part_ignore -and \( $opt_name_filter \) $cmd_size
#@todo -print0 revert back and use -0 in xargs?
}

function prepare_prefilter_input_from_cat {
	cat $1
}

function main_work {
	local input_function=$1
	local iteration=$2
	local prev_matched_files=$3
	local prev_matches=$4

	warning "Iteration $iteration: prefiltering."
	local itertmpfile=$tmpfile.$iteration
	
	$input_function $prev_matched_files|\
	tee >(xargs $cmd_part_parallelism -n 100 grep -F -no    --null -f $tmpfile.prep.grep.rules   >$itertmpfile.combos)|\
	        xargs $cmd_part_parallelism -n 100 grep -F -no -w --null -f $tmpfile.prep.grep.rules.w >$itertmpfile.combos.w

	sort -u $itertmpfile.combos $itertmpfile.combos.w >$itertmpfile.combos.all

	if [[ -s $itertmpfile.combos.all ]]
	then
		grep -f <(cut -d ':' -f 2 $itertmpfile.combos.all) $tmpfile.prep.allsedrules >$itertmpfile.rulesmatched
		warning "Iteration $iteration: replacing."
		cut -d '' -f 1 $itertmpfile.combos.all |sort -u >$itertmpfile.matchedfiles
		xargs <$itertmpfile.matchedfiles $cmd_part_parallelism -n 1 -I '{}' bash -c "$loop_function $itertmpfile.combos.all $itertmpfile.rulesmatched '{}' -i"
		rm $itertmpfile.rulesmatched
		if [[ $opt_dots = 1 ]]
		then
			echo >&2
		fi
	else
		warning "Iteration $iteration: nothing to replace."
	fi
	warning "Iteration $iteration: done."
	if [[ $iteration -lt 5 && -s $itertmpfile.combos.all ]]
	then
		if diff -q $prev_matches $itertmpfile.combos.all >/dev/null
		then
			warning "Iteration $iteration: matchlist is the same as in previous iteration..."
		else
			main_work prepare_prefilter_input_from_cat $((iteration + 1)) $itertmpfile.matchedfiles $itertmpfile.combos.all
		fi
		rm $itertmpfile.matchedfiles
	fi
	rm $itertmpfile.combos $itertmpfile.combos.w $itertmpfile.combos.all
	return 0
}

function loop_main_replace {
	findresult=$1
	rulesmatched=$2
	filename=$3
	inplaceflag=$4
	
	if [[ $opt_dots = 1 ]]
	then
		echo -n "," >&2
	fi

	sed $inplaceflag -b -f <(
		for patternwithline in $(grep --text $filename $findresult|cut -d '' -f 2)
		do
			line=${patternwithline/:*/}
			pattern=${patternwithline/*:/}
			grep -e $pattern $rulesmatched|sed "s/^/$line/"
		done
	) $filename
}
export -f loop_main_replace

function loop_decorated_mode {
	findresult=$1
	rulesmatched=$2
	filename=$3

	verbose "actual file: $filename"
	workfile=$filename.$$
	verbose "temp file: $workfile"
	cp -a "$filename" "$workfile"
	main_replace "$findresult" "$rulesmatched" "$filename" '' >"$workfile"
	diff=$(diff -uwb "$filename" "$workfile")
	if [[ $? = 0 ]]
	then
		verbose "nothing changed"
		rm "$workfile"
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
				mv "$filename" "$workfile.BAK"
			fi
			mv "$workfile" "$filename"
		else
			rm "$workfile"
		fi
	fi
}
export -f loop_decorated_mode

init_variables

parse_basic_options "$@"
retval=$?

if [[ $retval == 0 ]]
then
	process_parameter_rules
	retval=$?
fi

if [[ $retval == 0 ]]
then
	if [[ $opt_debug = 1 ]]
	then
		set -x
	fi
	preprocess_rules
	main_work prepare_prefilter_input_from_find 0 '' /dev/null
	retval=$?
	rm $tmpfile.prep.grep.rules $tmpfile.prep.grep.rules.w $tmpfile.prep.allsedrules
	if [[ $opt_debug = 1 ]]
	then
		set +x
	fi
fi

if [[ "$SHUNIT_VERSION" = "" ]]
then
	exit $retval
else
	return $retval
fi
