function warning {
    echo "misspell-fixer: $*" >&2
}
export -f warning

function verbose {
    if [[ $opt_verbose = 1 ]]; then
        warning "$@"
    fi
}
export -f verbose

function initialise_variables {
    set -f

    export LC_CTYPE=C
    export LANG=C

    export opt_debug=0
    export opt_verbose=0
    export opt_show_diff=0
    export opt_real_run=0
    export opt_backup=1
    export opt_dots=0
    export bash_arg

    export opt_whitelist_save=0
    export opt_whitelist_filename=".misspell-fixer.ignore"

    rules_safe0="${rules_directory}/safe.0.sed"
    rules_safe1="${rules_directory}/safe.1.sed"
    rules_safe2="${rules_directory}/safe.2.sed"
    rules_safe3="${rules_directory}/safe.3.sed"
    rules_not_so_safe="${rules_directory}/not-so-safe.sed"
    rules_gb_to_us="${rules_directory}/gb-to-us.sed"
    export enabled_rules="$rules_safe0"

    export cmd_part_ignore_scm="\
        -o -iname .git\
        -o -iname .svn\
        -o -iname .hg\
        -o -iname CVS"
    export cmd_part_ignore_bin="\
        -o -iname *.gif\
        -o -iname *.jpg\
        -o -iname *.jpeg\
        -o -iname *.png\
        -o -iname *.zip\
        -o -iname *.gz\
        -o -iname *.bz2\
        -o -iname *.xz\
        -o -iname *.rar\
        -o -iname *.po\
        -o -iname *.pdf\
        -o -iname *.woff\
        -o -iname *.mov\
        -o -iname *.mp4\
        -o -iname yarn.lock\
        -o -iname package-lock.json\
        -o -iname composer.lock\
        -o -iname *.mo"
    export cmd_part_ignore_gitignore=""
    export cmd_part_ignore

    export cmd_part_parallelism

    export loop_function=apply_rules_on_one_file
    export prefilter_progress_function=prefilter_progress_none

    export opt_name_filter=''
    export cmd_size="-and ( -size -1024k )"  # find will ignore files > 1MB
    export smart_sed

    export directories

    export tmpfile=.misspell-fixer.$$

    GREP=$(ggrep --version >/dev/null 2>&1 && \
        echo 'ggrep' || \
        echo 'grep')
    export GREP
}

function process_command_arguments {
    local OPTIND
    while getopts ":dvorfsibnRVDGmughWN:P:" opt; do
        case $opt in
            d)
                warning "-d Enable debug mode."
                opt_debug=1
                bash_arg=x
            ;;
            v)
                warning "-v Enable verbose mode."
                opt_verbose=1
            ;;
            o)
                warning "-o Print dots for each file scanned,"\
                    "comma for each file fix iteration/file."
                opt_dots=1
                prefilter_progress_function=prefilter_progress_dots
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
            G)
                warning "-G Respect .gitignore."
                for i in $(git ls-files --others --ignored --exclude-standard)
                do
                    cmd_part_ignore_gitignore="$cmd_part_ignore_gitignore -o -name $i"
                done
            ;;
            n)
                warning "-n Disable backups."
                opt_backup=0
            ;;
            u)
                warning "-u Enable unsafe rules."
                enabled_rules="$enabled_rules $rules_not_so_safe"
            ;;
            R)
                warning "-R Enable rare rules."
                enabled_rules="$enabled_rules $rules_safe1"
            ;;
            V)
                warning "-V Enable very-rare rules."
                enabled_rules="$enabled_rules $rules_safe2"
            ;;
            D)
                warning "-D Enable rules from lintian.debian.org / spelling."
                enabled_rules="$enabled_rules $rules_safe3"
            ;;
            m)
                warning "-m Disable max-size check. "\
                    "Default is to ignore files > 1MB."
                cmd_size=" "
            ;;
            g)
                warning "-g Enable GB to US rules."
                enabled_rules="$enabled_rules $rules_gb_to_us"
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
                d="dirname ${BASH_SOURCE[0]}"
                if [[ -f "$($d)"/../README.md ]]; then
                    cat "$($d)"/../README.md
                else
                    zcat /usr/share/doc/misspell-fixer/README.md.gz
                fi
                return 10
            ;;
            W)
                warning "-W Save found misspelled file entries into"\
                    "$opt_whitelist_filename instead of fixing them."
                opt_whitelist_save=1
            ;;
            \?)
                warning "Invalid option: -$OPTARG"
                return 100
            ;;
            :)
                warning "Option -$OPTARG requires an argument."
                return 101
            ;;
        esac
    done

    if [ -z "$opt_name_filter" ]; then
        opt_name_filter='-true'
    fi

    shift $((OPTIND-1))

    if [[ "$*" = "" ]]; then
        warning "Not enough arguments."\
            "(target directory not found) => Exiting."
        return 102
    fi

    directories=( "$@" )
    cmd_part_ignore="(\
        -iname $tmpfile*\
        -o -iname $opt_whitelist_filename\
        -o -iname *.BAK\
        $cmd_part_ignore_scm $cmd_part_ignore_bin $cmd_part_ignore_gitignore\
        ) -prune -o "
    warning "Target directories: ${directories[*]}"

    if [[ $opt_show_diff = 1 ||\
        $opt_backup = 1 ||\
        $opt_real_run = 0 ||\
        $opt_verbose = 1 ]]
    then
        loop_function=decorate_one_iteration
    fi

    return 0
}

function handle_parameter_conflicts {
    if [[ $opt_whitelist_save = 1 && $opt_real_run = 1 ]]; then
        warning "Whitelist cannot be generated in real run mode. => Exiting."
        return 103
    fi
    if [[ $opt_whitelist_save = 0 && $opt_real_run = 0 ]]; then
        warning "Real run (-r) has not been enabled."\
            "Files will not be changed. Use -r to override this."
    fi
    if [[ -z $cmd_part_parallelism ]]; then
        return 0
    fi
    if [[ $opt_show_diff = 1 ]]; then
        warning "Parallel mode cannot show diffs."\
            "Showing diffs is turned on. => Exiting."
        return 104
    fi
    return 0
}

function check_grep_version {
    local current_version
    current_version=$($GREP --version|head -1|sed -e 's/.* //g')
    local required_version="2.28"
    if printf '%s\n%s\n' "$required_version" "$current_version" | sort -VC
    then
        verbose "Your grep version is $current_version"\
            "which is at least the optimal: $required_version."
    else
        warning "!! Your grep version is $current_version"\
            "which is less than the optimal: $required_version."\
            "This may degrade misspell fixer's performance"\
            "significantly! (100x) !!"
    fi
}

function check_sed_arguments {
    if sed -b 2>&1 |$GREP -q illegal
    then
        # OS/X
        smart_sed=0
    else
        # Everything else
        smart_sed=1
    fi
}
