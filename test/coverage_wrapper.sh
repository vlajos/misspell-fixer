#!/bin/bash

d=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=lib/initialisation_functions.sh
source "$d/../lib/initialisation_functions.sh"
# shellcheck source=lib/main_functions.sh
source "$d/../lib/main_functions.sh"

eval "$3" >>"$TEST_OUTPUT" 2>&1
