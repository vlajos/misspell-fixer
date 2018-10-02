#!/usr/bin/env bash

function preprocess_rules {
    grep -vh 'bin/sed' $enabled_rules > "$tmpfile.prep.allsedrules"
    grep    '\\b' $tmpfile.prep.allsedrules|sed -e 's/^s\///g' -e 's/\/.*g//g' -e 's/\\b//g'    >$tmpfile.prep.grep.rules.w
    grep -v '\\b' $tmpfile.prep.allsedrules|sed -e 's/^s\///g' -e 's/\/.*g//g'          >$tmpfile.prep.grep.rules
}

function prepare_prefilter_input_from_find {
    find ${directories[*]} $cmd_part_ignore -type f -and \( $opt_name_filter \) $cmd_size -print0
}

function prepare_prefilter_input_from_cat {
    while read -r filename
    do
        printf '%s\0' "$filename"
    done <"$1"
}

function prefilter_progress_none {
    cat >/dev/null
}

function prefilter_progress_dots {
    while IFS= read -r -d '' filename
    do
        echo -n "." >&2
    done
}

function main_work {
    local input_function=$1
    local iteration=$2
    local prev_matched_files=$3
    local prev_matches=$4
    local itertmpfile=$tmpfile.$iteration

    warning "Iteration $iteration: prefiltering."

    $input_function "$prev_matched_files"|\
    tee >($prefilter_progress_function) \
        >(xargs -0 $cmd_part_parallelism -n 100 grep --text -F -noH     -f "$tmpfile.prep.grep.rules"   >"$itertmpfile.combos")|\
          xargs -0 $cmd_part_parallelism -n 100 grep --text -F -noH -w  -f "$tmpfile.prep.grep.rules.w" >"$itertmpfile.combos.w"

    sort -u "$itertmpfile.combos" "$itertmpfile.combos.w" >"$itertmpfile.combos.all"

    if [[ -s "$opt_whitelist_filename" ]]
    then
        warning "Skipping whitelisted entries based on $opt_whitelist_filename."
        grep -vf $opt_whitelist_filename "$itertmpfile.combos.all" >"$itertmpfile.combos.all.onlynonwhitelisted"
        mv "$itertmpfile.combos.all.onlynonwhitelisted" "$itertmpfile.combos.all"
    fi

    if [[ $opt_verbose = 1 ]]
    then
        verbose "Results of prefiltering: (filename:line:pattern)"
        cat "$itertmpfile.combos.all" >&2
    fi

    if [[ -s $itertmpfile.combos.all ]]
    then
        if [[ $opt_whitelist_save = 1 ]]
        then
            warning "Saving found misspells into $opt_whitelist_filename."
            sed -e 's/^/^/' "$itertmpfile.combos.all" >> "$opt_whitelist_filename"
        else
            if [[ $opt_real_run = 0 ]]
            then
                warning "Real run (-r) has not been enabled. Files will not be changed. Use -r to override this."
            fi
            grep --text -f <(cut -d ':' -f 3 "$itertmpfile.combos.all") "$tmpfile.prep.allsedrules" >"$itertmpfile.rulesmatched"
            warning "Iteration $iteration: replacing."
            cut -d ':' -f 1 "$itertmpfile.combos.all" |sort -u >"$itertmpfile.matchedfiles"
            xargs <"$itertmpfile.matchedfiles" $cmd_part_parallelism -n 1 -I '{}' $COVERAGE_WRAPPER bash -c$bash_arg "$loop_function $itertmpfile.combos.all $itertmpfile.rulesmatched '{}' 1"
            rm "$itertmpfile.rulesmatched"
            if [[ $opt_dots = 1 ]]
            then
                echo >&2
            fi
        fi
    else
        warning "Iteration $iteration: nothing to replace."
    fi
    warning "Iteration $iteration: done."
    if [[ $iteration -lt 5 && -s "$itertmpfile.combos.all" && $opt_real_run = 1 ]]
    then
        if diff --text -q "$prev_matches" "$itertmpfile.combos.all" >/dev/null
        then
            warning "Iteration $iteration: matchlist is the same as in previous iteration..."
        else
            main_work prepare_prefilter_input_from_cat $((iteration + 1)) "$itertmpfile.matchedfiles" "$itertmpfile.combos.all"
        fi
    fi
    if [[ -f $itertmpfile.matchedfiles ]]
    then
        rm "$itertmpfile.matchedfiles"
    fi
    rm "$itertmpfile.combos" "$itertmpfile.combos.w" "$itertmpfile.combos.all"
    return 0
}

function loop_main_replace {
    local findresult=$1
    local rulesmatched=$2
    local filename=$3
    local inplaceflag=$4

    if [[ $opt_dots = 1 ]]
    then
        echo -n "," >&2
    fi

    local sed=('sed')
    if [[ $smart_sed = 1 ]]
    then
        # -b is useful on windows, harmless on linux, but OS/X sed does not like it.
        sed=("${sed[@]}" '-b')
        if [[ $inplaceflag = 1 ]]
        then
            sed=("${sed[@]}" '-i')
        fi
    else
        if [[ $inplaceflag = 1 ]]
        then
            # OS/X sed needs separate arguments
            sed=("${sed[@]}" '-i' '')
        fi
    fi

    "${sed[@]}" -f <(
        grep --text "$filename" "$findresult"|\
        cut -d ':' -f 2,3|\
        while IFS=: read -r line pattern
        do
            grep --text -e "$pattern" "$rulesmatched"|sed "s/^/$line/"
        done
    ) "$filename"
}
export -f loop_main_replace

function loop_decorated_mode {
    local findresult=$1
    local rulesmatched=$2
    local filename=$3
    # Passed, but not used at the moment:
    #local inplace=$4

    verbose "actual file: $filename"
    local workfile=$filename.$$
    verbose "temp file: $workfile"
    if [[ -f $workfile ]]
    then
        warning "Temp file ($workfile) for ($filename) already exists. Skipping it."
        return 1
    fi
    cp -a "$filename" "$workfile"
    loop_main_replace "$findresult" "$rulesmatched" "$filename" 0 >"$workfile"
    if diff=$(diff -u "$filename" "$workfile")
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
                mv -n "$filename" "$workfile.BAK"
            fi
            mv "$workfile" "$filename"
        else
            rm "$workfile"
        fi
    fi
}
export -f loop_decorated_mode
