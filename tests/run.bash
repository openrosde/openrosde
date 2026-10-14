#!/bin/bash

# This script runs the test suites of 'tests/' in a Debian container, with the repository mounted read-only and no network, so a suite can change nothing outside the container.
# A test suite is any other Bash script of 'tests/', which stubs the outside commands it needs and ends with a failure status when one of its checks fails.
#
# Usage: bash ./tests/run.bash [test-suite]
#
# [test-suite]: The name of the one suite to run, such as 'check-terminator-parity'.
#               Default runs every suite.

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Set the Debian image the suites run in.
OPENROSDE_TEST_DEBIAN_IMAGE="debian:bookworm-slim"

################################################################################

# List the suites to run: the one given as argument, or every suite.
OPENROSDE_TEST_SUITE_NAMES=()
if [ -n "$1" ]; then
  if [ ! -f "${OPENROSDE_ROOT_DIR}/tests/$1.bash" ]; then
    echo "No test suite 'tests/$1.bash' found."
    exit 1
  fi
  OPENROSDE_TEST_SUITE_NAMES+=("$1")
else
  for OPENROSDE_TEST_SUITE_FILE in "${OPENROSDE_ROOT_DIR}"/tests/*.bash; do
    if [ "$(basename "${OPENROSDE_TEST_SUITE_FILE}")" != "run.bash" ]; then
      OPENROSDE_TEST_SUITE_NAMES+=("$(basename "${OPENROSDE_TEST_SUITE_FILE}" .bash)")
    fi
  done
fi

################################################################################

# Run every suite in its own container, and fail if any suite fails.
OPENROSDE_FAILED_SUITE_NAMES=""
for OPENROSDE_TEST_SUITE_NAME in "${OPENROSDE_TEST_SUITE_NAMES[@]}"; do
  echo "Running the test suite '${OPENROSDE_TEST_SUITE_NAME}'."
  if docker run --rm --network none \
      --volume "${OPENROSDE_ROOT_DIR}:/openrosde:ro" \
      --workdir /openrosde \
      "${OPENROSDE_TEST_DEBIAN_IMAGE}" \
      bash "tests/${OPENROSDE_TEST_SUITE_NAME}.bash"; then
    echo "The test suite '${OPENROSDE_TEST_SUITE_NAME}' passed."
  else
    echo "The test suite '${OPENROSDE_TEST_SUITE_NAME}' failed."
    OPENROSDE_FAILED_SUITE_NAMES="${OPENROSDE_FAILED_SUITE_NAMES} ${OPENROSDE_TEST_SUITE_NAME}"
  fi
done

################################################################################

# Report the result.
echo "Ran ${#OPENROSDE_TEST_SUITE_NAMES[@]} test suites."
if [ -n "${OPENROSDE_FAILED_SUITE_NAMES}" ]; then
  echo "These test suites failed:${OPENROSDE_FAILED_SUITE_NAMES}"
  exit 1
fi
