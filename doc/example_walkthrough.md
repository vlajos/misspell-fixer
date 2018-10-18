# Misspell fixer example walkthrough

## Example data

### Input file: example_test.txt

    line1
    line2 amout
    line3retreive
    line4 retreive

### (Just the relevant) patterns

    s/amout/amount/g
    s/\bretreive\b/retrieve/g

## Function calls and temporary files

### prepare_rules_for_prefiltering()

#### Collect all sed rules into one file: `.misspell-fixer.X.prepared.sed.all_rules`

    s/amout/amount/
    s/\bretreive\b/retrieve/g

#### Save the non word boundary specific patterns into: `.misspell-fixer.X.prepared.grep.patterns`

    amout

#### Save the word boundary specific patterns into: `.misspell-fixer.X.prepared.grep.patterns.word_limited`

    retreive

### iterate_through_targets()->execute_prefiltering() (X=0)

#### Save the non word boundary specific matches into: `.misspell-fixer.X.0.matches`

    example_test.txt:2:amout

#### Save the word boundary specific matches into: `.misspell-fixer.X.0.matches.word_limited`

    example_test.txt:4:retreive

#### Merge all matches into: `.misspell-fixer.X.0.matches.all`

    example_test.txt:2:amout
    example_test.txt:4:retreive

### iterate_through_targets()->iterate_through_prefiltered_files()

#### Select the potentially matching sed rules into: `.misspell-fixer.X.0.sed.matched_rules`

    s/\bretreive\b/retrieve/g
    s/amout/amount/g
    s/\bretreived\b/retrieved/g

#### Save the matched file names into `.misspell-fixer.X.0.matched_files`

    example_test.txt

### iterate_through_targets()->apply_rules_on_one_file()

Create a targeted fix recipe which fix one kind of error in one line only, then apply it.

    2s/amout/amount/g
    4s/\bretreive\b/retrieve/g
    4s/\bretreived\b/retrieved/g

### Then iterate until there are new matches. (X=X+1)
