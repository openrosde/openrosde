#!/bin/bash

# This script runs the test suites of the OpenRoSDE scripts in 'tests/suites/', each on scratch copies of the repository with every outside command stubbed, so that no test builds an image, starts a container, or reaches a robot.
# On a machine with Docker, it runs them in a Debian container with 'tmux', built once as the local image 'openrosde-tests:local', with the repository mounted read-only and no network, so that a suite changes nothing outside the container.
# Inside a container that has no Docker, such as a Debian job of the CI with 'tmux' installed, it runs them directly.
#
# Usage: bash ./tests/run.bash [suite ...]
#
# [suite]: Name of a suite of 'tests/suites/', such as 'test-extension-parts', to run only that suite.
#          Default is every suite.

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################################################################################

# Run the suites in the Debian container when Docker is available, unless this already runs inside that container.
if [ "${OPENROSDE_TEST_IN_CONTAINER}" != "true" ] && command -v docker > /dev/null 2>&1; then
  docker build --quiet --tag openrosde-tests:local - > /dev/null <<'EOF' || exit 1
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends tmux \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
EOF
  docker run --rm --network none \
    --env OPENROSDE_TEST_IN_CONTAINER=true \
    --volume "${OPENROSDE_ROOT_DIR}:/src:ro" \
    openrosde-tests:local \
    bash /src/tests/run.bash "$@"
  exit $?
fi

################################################################################

# List the suites to run, every suite by default.
OPENROSDE_TEST_SUITE_FILES=()
if [ "$#" -eq 0 ]; then
  OPENROSDE_TEST_SUITE_FILES=("${OPENROSDE_ROOT_DIR}"/tests/suites/*.bash)
else
  for OPENROSDE_TEST_SUITE_NAME in "$@"; do
    OPENROSDE_TEST_SUITE_FILES+=("${OPENROSDE_ROOT_DIR}/tests/suites/${OPENROSDE_TEST_SUITE_NAME%.bash}.bash")
  done
fi

# Run every suite in a Bash process of its own, and report the suites that fail.
OPENROSDE_TEST_FAILED_SUITES=""
for OPENROSDE_TEST_SUITE_FILE in "${OPENROSDE_TEST_SUITE_FILES[@]}"; do
  echo "Suite '$(basename "${OPENROSDE_TEST_SUITE_FILE}" .bash)':"
  if ! OPENROSDE_TEST_SOURCE_DIR="${OPENROSDE_ROOT_DIR}" bash "${OPENROSDE_TEST_SUITE_FILE}"; then
    OPENROSDE_TEST_FAILED_SUITES="${OPENROSDE_TEST_FAILED_SUITES} $(basename "${OPENROSDE_TEST_SUITE_FILE}" .bash)"
  fi
  echo ""
done
if [ -n "${OPENROSDE_TEST_FAILED_SUITES}" ]; then
  echo "Failed suites:${OPENROSDE_TEST_FAILED_SUITES}"
  exit 1
fi
echo "All suites passed."
