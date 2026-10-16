#!/bin/bash

# This suite checks that the 'tmux' session of every platform of the core, and of every platform cloned into 'extensions/' of the repository under test, runs the same launch entry points as its Terminator layouts.
# 'AGENTS.md' asks to keep 'tmux/<platform>.panes' in step with 'terminator/<platform>.config' until Terminator is retired, since the pane files were generated from the layouts.
# For each layout 'openrosde-<platform>-term-11-<layout>' of a Terminator config, it compares the launch files and arguments of the terminals with the panes of '<layout>' in 'tmux/<platform>.panes' of the same folder and 'tmux/openrosde.panes' of the core, leaving out the shells on both sides.
# It only reads the files of the repository under test, so it needs no scratch copy and starts nothing.
#
# Usage: bash ./tests/run.bash test-terminator-parity

################################################################################

# Load the helpers.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"

# Print the launch entry points of a layout of a Terminator config, one per line and sorted, from the terminals whose command names a launch file.
function openrosde-test-print-terminator-launches () {
  awk -v layout="[[$2]]" '
    /^\[/ { active = 0 }
    /^  \[\[/ { active = ($1 == layout) }
    active && $1 == "command" {
      sub(/^.*[$][{]OPENROSDE_DOCKER_PROJECT[}]/, "")
      $1 = $1
      if ($0 != "") print
    }
  ' "$1" | sort
}

# Print the launch entry points of a layout in pane files, one per line and sorted, without the shells of the container and of the host.
function openrosde-test-print-tmux-launches () {
  awk -v layout="$1" '
    /^#/ || NF == 0 { next }
    $1 == "*" || index("," $1 ",", "," layout ",") {
      $1 = ""
      $2 = ""
      $0 = $0
      $1 = $1
      if ($0 != "shell" && $0 != "host") print
    }
  ' "${@:2}" | sort
}

################################################################################

# List the Terminator configs of the core and of the clones, and say so when there is none, since the platforms live in repositories of their own, which a developer clones into 'extensions/'.
OPENROSDE_TEST_CONFIG_FILES=()
for OPENROSDE_TEST_CONFIG_FILE in "${OPENROSDE_TEST_SOURCE_DIR}"/terminator/*.config "${OPENROSDE_TEST_SOURCE_DIR}"/extensions/*/terminator/*.config "${OPENROSDE_TEST_SOURCE_DIR}"/extensions/*/parts/*/terminator/*.config; do
  if [ -f "${OPENROSDE_TEST_CONFIG_FILE}" ]; then
    OPENROSDE_TEST_CONFIG_FILES+=("${OPENROSDE_TEST_CONFIG_FILE}")
  fi
done
if [ "${#OPENROSDE_TEST_CONFIG_FILES[@]}" -eq 0 ]; then
  echo "No Terminator config in the core or in a clone of 'extensions/', so no layout to compare."
fi

# Check every layout of every Terminator config against the panes of the same layout.
for OPENROSDE_TEST_CONFIG_FILE in "${OPENROSDE_TEST_CONFIG_FILES[@]}"; do
  [ -f "${OPENROSDE_TEST_CONFIG_FILE}" ] || continue
  OPENROSDE_TEST_PLATFORM_NAME="$(basename "${OPENROSDE_TEST_CONFIG_FILE}" .config)"
  OPENROSDE_TEST_CONFIG_ROOT_DIR="$(dirname "$(dirname "${OPENROSDE_TEST_CONFIG_FILE}")")"
  OPENROSDE_TEST_PANES_FILE="${OPENROSDE_TEST_CONFIG_ROOT_DIR}/tmux/${OPENROSDE_TEST_PLATFORM_NAME}.panes"
  echo "Platform '${OPENROSDE_TEST_PLATFORM_NAME}' in '.${OPENROSDE_TEST_CONFIG_ROOT_DIR#${OPENROSDE_TEST_SOURCE_DIR}}':"

  # A Terminator config needs the pane file of its platform, and at least one layout named after its platform, or a typo would leave it unchecked.
  openrosde-test-check "finds 'tmux/${OPENROSDE_TEST_PLATFORM_NAME}.panes' beside 'terminator/${OPENROSDE_TEST_PLATFORM_NAME}.config'" \
    "true" \
    "$([ -f "${OPENROSDE_TEST_PANES_FILE}" ] && echo true || echo false)"
  OPENROSDE_TEST_LAYOUT_NAMES="$(grep -o "^  \[\[openrosde-${OPENROSDE_TEST_PLATFORM_NAME}-term-11-[^]]*\]\]" "${OPENROSDE_TEST_CONFIG_FILE}" | tr -d ' []')"
  openrosde-test-check "finds the layouts 'openrosde-${OPENROSDE_TEST_PLATFORM_NAME}-term-11-<layout>' in 'terminator/${OPENROSDE_TEST_PLATFORM_NAME}.config'" \
    "true" \
    "$([ -n "${OPENROSDE_TEST_LAYOUT_NAMES}" ] && echo true || echo false)"
  if [ ! -f "${OPENROSDE_TEST_PANES_FILE}" ]; then
    continue
  fi

  # Each layout runs the same launch files and arguments in Terminator and in 'tmux'.
  for OPENROSDE_TEST_LAYOUT_NAME in ${OPENROSDE_TEST_LAYOUT_NAMES}; do
    OPENROSDE_TEST_SESSION_LAYOUT="${OPENROSDE_TEST_LAYOUT_NAME#openrosde-"${OPENROSDE_TEST_PLATFORM_NAME}"-term-11-}"
    openrosde-test-check "runs the launch entry points of the '${OPENROSDE_TEST_SESSION_LAYOUT}' Terminator layout of '${OPENROSDE_TEST_PLATFORM_NAME}' in its 'tmux' panes" \
      "$(openrosde-test-print-terminator-launches "${OPENROSDE_TEST_CONFIG_FILE}" "${OPENROSDE_TEST_LAYOUT_NAME}")" \
      "$(openrosde-test-print-tmux-launches "${OPENROSDE_TEST_SESSION_LAYOUT}" "${OPENROSDE_TEST_PANES_FILE}" "${OPENROSDE_TEST_SOURCE_DIR}/tmux/openrosde.panes")"
  done
done

################################################################################

# Report the result.
openrosde-test-finish-suite
