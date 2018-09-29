#!/bin/bash

export FUNCTIONS_ONLY_FOR_COVERAGE=1

source misspell-fixer

eval $3 >>$TEST_OUTPUT 2>&1
