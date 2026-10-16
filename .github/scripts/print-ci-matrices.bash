#!/bin/bash

# This script reads the child pipeline that 'gitlab-ci/generate-ci-pipeline.bash' prints, and prints the matrices of the jobs of GitHub Actions that mirror its image jobs and test jobs, as lines of 'GITHUB_OUTPUT'.
# It takes the variables that a job inherits from the hidden job it extends from 'gitlab-ci/openrosde-pipeline.yml', so the generator stays the one place that finds the platforms and the setups.
# It prints three lines:
#   platforms=<array>: one JSON object per image job of a platform, with 'job', 'platform', 'root', 'base', and 'sources', the folders that define its base image.
#   tests=<array>: one JSON object per test job, with 'job', 'setup', 'model-args', and the 'platform', 'root', and 'base' of the platform it runs, which are empty for the core alone.
#   platform-images=<names>: the platform images that the publish job publishes, separated by spaces.
# It fails on any value with a character other than letters, digits, and '_.,/ -', since the workflows pass every value on to the scripts of the CI.
#
# Usage: bash ./.github/scripts/print-ci-matrices.bash <generated-pipeline-file>
#
# <generated-pipeline-file>: The child pipeline that 'gitlab-ci/generate-ci-pipeline.bash' printed, such as 'openrosde-pipeline-generated.yml'.

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Check that the child pipeline exists.
if [ ! -f "$1" ]; then
  echo "Error: The child pipeline '$1' does not exist." >&2
  exit 1
fi

################################################################################

# Read the jobs of the shared jobs and of the child pipeline, written by the generator one key per line, and print one record per image job of a platform, per test job, and for the publish job, with tabs between the fields.
# A job starts at a key of the first column, its keys are indented by two spaces, and the items of 'needs' and the entries of 'variables' by four.
OPENROSDE_CI_RECORDS="$(awk '
  function strip_quotes(value) {
    if (value ~ /^".*"$/) {
      value = substr(value, 2, length(value) - 2)
    }
    return value
  }
  function variable(job, name) {
    if ((job, name) in variables) {
      return variables[job, name]
    }
    return variables[extended[job], name]
  }
  FNR == 1 {
    file_number++
  }
  /^[^[:space:]#][^:]*:[[:space:]]*$/ {
    job = $0
    sub(/:[[:space:]]*$/, "", job)
    section = ""
    if (file_number == 2) {
      job_names[++job_count] = job
    }
    next
  }
  /^[^[:space:]]/ {
    job = ""
    next
  }
  job != "" && /^  [A-Za-z_]+:/ {
    section = $1
    sub(/:$/, "", section)
    if (section == "extends") {
      value = $0
      sub(/^  extends:[[:space:]]*/, "", value)
      extended[job] = value
    }
    next
  }
  job != "" && section == "needs" && /^    - / {
    value = $0
    sub(/^    - /, "", value)
    needs[job] = needs[job] " " value
    next
  }
  job != "" && section == "variables" && /^    [A-Z0-9_]+:/ {
    name = $1
    sub(/:$/, "", name)
    value = $0
    sub(/^    [A-Z0-9_]+:[[:space:]]*/, "", value)
    variables[job, name] = strip_quotes(value)
    next
  }
  END {
    for (i = 1; i <= job_count; i++) {
      job = job_names[i]
      if (extended[job] == ".build-platform-image") {
        printf "platform\t%s\t%s\t%s\t%s\t%s\n", job, variable(job, "OPENROSDE_ROBOT_PLATFORM"), variable(job, "OPENROSDE_CI_PLATFORM_ROOT_DIR"), variable(job, "OPENROSDE_CI_BASE_IMAGE_NAME"), variable(job, "OPENROSDE_CI_BASE_SOURCE_DIRS")
      } else if (extended[job] == ".test-setup") {
        image_job = ""
        count = split(needs[job], needed_jobs, " ")
        for (j = 1; j <= count; j++) {
          if (image_job == "" && needed_jobs[j] ~ /^build-.*-image-job$/ && needed_jobs[j] != "build-mesh2glb-image-job") {
            image_job = needed_jobs[j]
          }
        }
        printf "test\t%s\t%s\t%s\t%s\n", job, variable(job, "OPENROSDE_CI_ROBOT_SETUP"), variable(job, "OPENROSDE_CI_ROBOT_MODEL_ARGS"), image_job
      } else if (job == "publish-images-job") {
        printf "publish\t%s\t%s\n", job, variable(job, "OPENROSDE_CI_PLATFORM_IMAGES")
      }
    }
  }
' "${OPENROSDE_ROOT_DIR}/gitlab-ci/openrosde-pipeline.yml" "$1")" || exit 1

# Refuse a child pipeline without any test job, such as one that the generator did not finish.
if ! printf '%s\n' "${OPENROSDE_CI_RECORDS}" | grep -q '^test'; then
  echo "Error: The child pipeline '$1' holds no test job." >&2
  exit 1
fi

# Refuse any value beyond the characters that names, folders, and options use.
mapfile -t OPENROSDE_CI_REFUSED_RECORDS < <(printf '%s\n' "${OPENROSDE_CI_RECORDS}" | grep -v -E $'^(platform|test|publish)(\t[A-Za-z0-9_.,/ -]*)+$')
if [ "${#OPENROSDE_CI_REFUSED_RECORDS[@]}" -gt 0 ]; then
  echo "Error: The child pipeline holds jobs with values that the workflows do not pass on:" >&2
  printf '  - %s\n' "${OPENROSDE_CI_REFUSED_RECORDS[@]}" >&2
  exit 1
fi

################################################################################

# Print the matrices, with every test job given the platform of the image job it needs, if any.
printf '%s\n' "${OPENROSDE_CI_RECORDS}" | jq --raw-input --slurp --raw-output '
  split("\n") | map(select(length > 0) | split("\t")) as $records
  | ($records | map(select(.[0] == "platform") | {job: .[1], platform: .[2], root: .[3], base: .[4], sources: .[5]})) as $platforms
  | ($platforms | map({key: .job, value: {platform, root, base}}) | from_entries) as $platforms_by_job
  | ($records | map(select(.[0] == "test") | {job: .[1], setup: .[2], "model-args": .[3]} + ($platforms_by_job[.[4]] // {platform: "", root: "", base: ""}))) as $tests
  | "platforms=\($platforms | tojson)",
    "tests=\($tests | tojson)",
    "platform-images=\($records | map(select(.[0] == "publish") | .[2]) | first // "")"
'
