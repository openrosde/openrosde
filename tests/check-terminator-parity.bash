#!/bin/bash

# This test suite checks that the 'tmux' session of every platform runs the same launch entry points as its Terminator layouts.
# 'AGENTS.md' asks to keep 'tmux/<platform>.panes' in step with 'terminator/<platform>.config' until Terminator is retired, since the pane files were generated from the layouts.
# For each layout 'openrosde-<platform>-term-11-<layout>' of a Terminator config, the suite compares the launch files and arguments of its terminals with the panes of '<layout>' in 'tmux/<platform>.panes' and 'tmux/openrosde.panes'.
# The shells are left out on both sides, and the suite only reads files, so it starts nothing.
#
# Usage: bash ./tests/check-terminator-parity.bash

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################################################################################

# Print the launch entry points of a layout of a Terminator config, one per line and sorted, from the terminals whose command names a launch file.
function openrosde-list-terminator-launches () {
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
function openrosde-list-tmux-launches () {
  local OPENROSDE_LAYOUT_NAME="$1"
  shift
  awk -v layout="${OPENROSDE_LAYOUT_NAME}" '
    /^#/ || NF == 0 { next }
    $1 == "*" || index("," $1 ",", "," layout ",") {
      $1 = ""
      $2 = ""
      $0 = $0
      $1 = $1
      if ($0 != "shell" && $0 != "host") print
    }
  ' "$@" | sort
}

################################################################################

# Compare every layout of every Terminator config with the panes of the same layout.
OPENROSDE_CHECKED_LAYOUT_COUNT=0
OPENROSDE_FAILED_LAYOUT_NAMES=""
for OPENROSDE_TERMINATOR_CONFIG in "${OPENROSDE_ROOT_DIR}"/terminator/*.config; do
  OPENROSDE_PLATFORM_NAME="$(basename "${OPENROSDE_TERMINATOR_CONFIG}" .config)"
  OPENROSDE_PLATFORM_PANES_FILE="${OPENROSDE_ROOT_DIR}/tmux/${OPENROSDE_PLATFORM_NAME}.panes"
  if [ ! -f "${OPENROSDE_PLATFORM_PANES_FILE}" ]; then
    echo "FAIL: '${OPENROSDE_PLATFORM_NAME}' has a Terminator config but no 'tmux/${OPENROSDE_PLATFORM_NAME}.panes'."
    OPENROSDE_FAILED_LAYOUT_NAMES="${OPENROSDE_FAILED_LAYOUT_NAMES} ${OPENROSDE_PLATFORM_NAME}"
    continue
  fi
  for OPENROSDE_TERMINATOR_LAYOUT in $(grep -o "^  \[\[openrosde-${OPENROSDE_PLATFORM_NAME}-term-11-[^]]*\]\]" "${OPENROSDE_TERMINATOR_CONFIG}" | tr -d ' []'); do
    OPENROSDE_SESSION_LAYOUT="${OPENROSDE_TERMINATOR_LAYOUT#openrosde-"${OPENROSDE_PLATFORM_NAME}"-term-11-}"
    OPENROSDE_LAYOUT_DIFFERENCES="$(diff \
      <(openrosde-list-terminator-launches "${OPENROSDE_TERMINATOR_CONFIG}" "${OPENROSDE_TERMINATOR_LAYOUT}") \
      <(openrosde-list-tmux-launches "${OPENROSDE_SESSION_LAYOUT}" "${OPENROSDE_PLATFORM_PANES_FILE}" "${OPENROSDE_ROOT_DIR}/tmux/openrosde.panes") \
      | grep '^[<>]' \
      | sed -e 's/^</    only in Terminator:/' -e 's/^>/    only in tmux:/')"
    OPENROSDE_CHECKED_LAYOUT_COUNT=$((OPENROSDE_CHECKED_LAYOUT_COUNT + 1))
    if [ -z "${OPENROSDE_LAYOUT_DIFFERENCES}" ]; then
      echo "PASS: '${OPENROSDE_PLATFORM_NAME}' runs the same launch entry points in '${OPENROSDE_SESSION_LAYOUT}'."
    else
      echo "FAIL: '${OPENROSDE_PLATFORM_NAME}' runs different launch entry points in '${OPENROSDE_SESSION_LAYOUT}':"
      echo "${OPENROSDE_LAYOUT_DIFFERENCES}"
      OPENROSDE_FAILED_LAYOUT_NAMES="${OPENROSDE_FAILED_LAYOUT_NAMES} ${OPENROSDE_PLATFORM_NAME}:${OPENROSDE_SESSION_LAYOUT}"
    fi
  done
done

################################################################################

# Report the result, and fail if any layout differs or no layout was found.
echo "Checked ${OPENROSDE_CHECKED_LAYOUT_COUNT} Terminator layouts against their 'tmux' panes."
if [ -n "${OPENROSDE_FAILED_LAYOUT_NAMES}" ]; then
  echo "These layouts differ:${OPENROSDE_FAILED_LAYOUT_NAMES}"
  exit 1
fi
if [ "${OPENROSDE_CHECKED_LAYOUT_COUNT}" -eq 0 ]; then
  echo "No Terminator layout was found in '${OPENROSDE_ROOT_DIR}/terminator/'."
  exit 1
fi
