#!/usr/bin/env bash
set -e

# Script for testing a student's local solution to a single GDScript exercise.
# 
# This script is intended to be run from any exercise subdirectory from the
# Exercism GDScript track, but can live one directory higher than the
# exercise subdirectories for convenience.

slug=$(basename "$(pwd)")
missing_gd_msg="Normally, the exercise subdirectory created by the exercism download command should contain this file."
general_help_msg="Please see https://exercism.org/docs/tracks/gdscript/installation for details."
if [ ! -f "${slug//-/_}_test.gd" ]; then
    echo "Missing test file: ${slug//-/_}_test.gd"
    echo $missing_gd_msg
    echo $general_help_msg
    exit 1
fi
if [ ! -f "${slug//-/_}.gd" ]; then
    echo "Missing solution file: ${slug//-/_}.gd"
    echo $missing_gd_msg
    echo $general_help_msg
    exit 1
fi
if [ ! -f "/opt/exercism/gdscript/test-runner/bin/run.sh" ]; then
    echo "Missing test runner file: /opt/exercism/gdscript/test-runner/bin/run.sh"
    echo $general_help_msg
    exit 1
fi

solution_dir="$(pwd)"
output_dir="${solution_dir}/.test-output"
results_file="${output_dir}/results.json"
mkdir -p "${output_dir}"

(cd /opt/exercism/gdscript/test-runner && godot --headless -s bin/test_runner.gd -- "${slug}" "${solution_dir}") || {
    echo "Test runner script failed."
    exit 1
}