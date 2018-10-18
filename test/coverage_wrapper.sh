#!/bin/bash

source "lib/initialisation_functions.sh"
source "lib/main_functions.sh"

eval "$3" >>"$TEST_OUTPUT" 2>&1
