function prepare_rules_for_prefiltering {
    "$GREP"\
        -vh\
        'bin/sed'\
        $enabled_rules\
        >"$tmpfile.prepared.sed.all_rules"
    "$GREP"\
        '\\b'\
        "$tmpfile.prepared.sed.all_rules"|\
        sed\
            -e 's/^s\///g'\
            -e 's/\/.*g//g'\
            -e 's/\\b//g'\
            >"$tmpfile.prepared.grep.patterns.word_limited"
    "$GREP"\
        -v '\\b'\
        "$tmpfile.prepared.sed.all_rules"|\
        sed\
            -e 's/^s\///g'\
            -e 's/\/.*g//g'\
            >"$tmpfile.prepared.grep.patterns"
}

function list_files_from_find {
    find\
        ${directories[*]}\
        $cmd_part_ignore\
        -type f\
        -and \( $opt_name_filter \)\
        $cmd_size\
        -print
}

function list_files_from_last_iteration {
    cat "$1"
}

function prefilter_progress_none {
    cat >/dev/null
}

function prefilter_progress_dots {
    while IFS= read -r -d '' filename; do
        echo -n "." >&2
    done
}

function execute_prefiltering {
    local file_lister_function=$1
    local iteration_tmp_file=$2
    local previously_matched_files=$3

    "$file_lister_function"\
        "$previously_matched_files"|\
        grep -Fvx -f "$tmpfile.git.ignore"|\
        while read -r filename; do
            printf '%s\0' "$filename"
        done|\
        tee\
            >($prefilter_progress_function)\
            >(xargs\
                -0\
                $cmd_part_parallelism\
                -n 100\
                "$GREP"\
                    --text\
                    -F\
                    -noH\
                    -f "$tmpfile.prepared.grep.patterns"\
                >"$iteration_tmp_file.matches"\
            )\
        |\
            xargs\
                -0\
                $cmd_part_parallelism\
                -n 100\
                "$GREP"\
                    --text\
                    -F\
                    -noH\
                    -w\
                    -f "$tmpfile.prepared.grep.patterns.word_limited"\
                >"$iteration_tmp_file.matches.word_limited"

    sort\
        -u\
        "$iteration_tmp_file.matches"\
        "$iteration_tmp_file.matches.word_limited" |\
    "$GREP" ':' \
        >"$iteration_tmp_file.matches.all"
}

function apply_whitelist_on_prefiltered_list {
    local iteration_tmp_file=$1

    if [[ -s "$opt_whitelist_filename" ]]; then
        warning "Skipping whitelisted entries based"\
            "on $opt_whitelist_filename."
        "$GREP"\
            -v\
            -f "$opt_whitelist_filename"\
            "$iteration_tmp_file.matches.all"\
            >"$iteration_tmp_file.matches.all.only_non_whitelisted"
        mv\
            "$iteration_tmp_file.matches.all.only_non_whitelisted"\
            "$iteration_tmp_file.matches.all"
    fi
}

function iterate_through_prefiltered_files {
    local iteration=$1
    local iteration_tmp_file=$2

    "$GREP"\
        --text\
        -f <(\
            cut\
            -d ':'\
            -f 3\
            "$iteration_tmp_file.matches.all"
            )\
        "$tmpfile.prepared.sed.all_rules"\
        >"$iteration_tmp_file.sed.matched_rules"
    warning "Iteration $iteration: processing."
    cut\
        -d ':'\
        -f 1\
        "$iteration_tmp_file.matches.all"|\
    sort -u >"$iteration_tmp_file.matched_files"
    xargs\
        <"$iteration_tmp_file.matched_files"\
        $cmd_part_parallelism\
        -I '{}'\
        -n 1\
        $COVERAGE_WRAPPER\
        bash\
            -c$bash_arg\
            "$loop_function\
            $iteration_tmp_file.matches.all\
            $iteration_tmp_file.sed.matched_rules\
            '{}'\
            1"
    rm "$iteration_tmp_file.sed.matched_rules"
    if [[ $opt_dots = 1 ]]; then
        echo >&2
    fi
}

function iterate_through_targets {
    local file_lister_function=$1
    local iteration=$2
    local previously_matched_files=$3
    local prev_matches=$4

    local iteration_tmp_file=$tmpfile.$iteration
    local retval=0

    warning "Iteration $iteration: prefiltering."

    execute_prefiltering\
        "$file_lister_function"\
        "$iteration_tmp_file"\
        "$previously_matched_files"

    apply_whitelist_on_prefiltered_list "$iteration_tmp_file"

    if [[ $opt_verbose = 1 ]]; then
        verbose "Results of prefiltering: (filename:line:pattern)"
        cat "$iteration_tmp_file.matches.all" >&2
    fi

    if [[ -s $iteration_tmp_file.matches.all ]]; then
        if [[ $opt_whitelist_save = 1 ]]; then
            warning "Saving found misspells into $opt_whitelist_filename."
            sed\
                -e 's/^/^/'\
                "$iteration_tmp_file.matches.all"\
                >> "$opt_whitelist_filename"
            retval=11
        else
            iterate_through_prefiltered_files\
                "$iteration"\
                "$iteration_tmp_file"
            retval=1
        fi
    else
        warning "Iteration $iteration: nothing to replace."
    fi
    warning "Iteration $iteration: done."
    if [[\
        $iteration -lt 5 &&\
        -s "$iteration_tmp_file.matches.all" &&\
        $opt_real_run = 1 ]]
    then
        if diff\
            --text\
            -q\
            "$prev_matches"\
            "$iteration_tmp_file.matches.all"\
            >/dev/null
        then
            warning "Iteration $iteration: matchlist is the"\
                "same as in previous iteration..."
        else
            iterate_through_targets\
                list_files_from_last_iteration\
                $((iteration + 1))\
                "$iteration_tmp_file.matched_files"\
                "$iteration_tmp_file.matches.all"
            retval=$(($? + 1 ))
        fi
    fi
    if [[ -f $iteration_tmp_file.matched_files ]]; then
        rm "$iteration_tmp_file.matched_files"
    fi
    rm\
        "$iteration_tmp_file.matches"\
        "$iteration_tmp_file.matches.word_limited"\
        "$iteration_tmp_file.matches.all"
    return $retval
}

function apply_rules_on_one_file {
    local all_matches=$1
    local sed_rules_matched=$2
    local filename=$3
    local inplaceflag=$4

    if [[ $opt_dots = 1 ]]; then
        echo -n "," >&2
    fi

    local sed=('sed')
    if [[ $smart_sed = 1 ]]; then
        # -b is useful on windows, harmless on linux, but OS/X sed does not like it.
        sed=("${sed[@]}" '-b')
        if [[ $inplaceflag = 1 ]]; then
            sed=("${sed[@]}" '-i')
        fi
    else
        if [[ $inplaceflag = 1 ]]; then
            # OS/X sed needs separate arguments
            sed=("${sed[@]}" '-i' '')
        fi
    fi

    "${sed[@]}" -f <(
        "$GREP" --text "$filename" "$all_matches"|\
        cut -d ':' -f 2,3|\
        while IFS=: read -r line pattern; do
            "$GREP" --text -e "$pattern" "$sed_rules_matched"|sed "s/^/$line/"
        done
    ) "$filename"
}
export -f apply_rules_on_one_file

function decorate_one_iteration {
    local all_matches=$1
    local sed_rules_matched=$2
    local filename=$3
    # Passed, but not used at the moment:
    #local inplace=$4

    verbose "actual file: $filename"
    local workfile=$filename.$$
    verbose "temp file: $workfile"
    if [[ -f $workfile ]]; then
        warning "Temp file ($workfile) for ($filename) already exists."\
            "Skipping it."
        return 1
    fi
    cp -a "$filename" "$workfile"
    apply_rules_on_one_file\
        "$all_matches"\
        "$sed_rules_matched"\
        "$filename"\
        0\
        >"$workfile"
    if diff=$(diff -u "$filename" "$workfile"); then
        verbose "nothing changed"
        rm "$workfile"
    else
        if [[ $opt_show_diff = 1 ]]; then
            echo "$diff"
        fi
        if [[ $opt_real_run = 1 ]]; then
            verbose "misspellings are fixed!"
            if [[ $opt_backup = 1 ]]; then
                mv -n "$filename" "$workfile.BAK"
            fi
            mv "$workfile" "$filename"
        else
            rm "$workfile"
        fi
    fi
}
export -f decorate_one_iteration
