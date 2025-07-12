#!/usr/bin/env sh

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: path to solution folder
# $3: path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer path/to/solution/folder/ path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug path/to/solution/folder/ path/to/output/directory/"
    exit 1
fi

slug="$1"
solution_dir=$(realpath "${2%/}")
output_dir=$(realpath "${3%/}")
results_file="${output_dir}/results.json"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

# Create Godot directories
export XDG_CONFIG_HOME=/tmp/config
export XDG_DATA_HOME=/tmp/local/share
export XDG_CACHE_HOME=/tmp/cache

mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"

echo "${slug}: testing..."

# Switch to where the script lives in case called from elsewhere
OLD_DIR=$(pwd)
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

# Run the tests for the provided implementation file
godot --headless -s ./test_runner.gd 2>/tmp/stderr -- "${slug}" "${solution_dir}" "${output_dir}"

# Switch back to calling dir
cd "$OLD_DIR" || exit 1

echo "${slug}: done"
