#!/bin/bash

# This script prints the settings of a run of the reusable workflow 'extension.yml', as lines of 'GITHUB_OUTPUT', once it has checked them.
# The extension under test is named after the repository that calls the workflow, unless the caller names its folder, and the published images to test with take the tag that matches the version of the core, unless the caller names one.
# It prints two lines:
#   extension-name=<name>: the folder of the extension under test in 'extensions/'.
#   image-tag=<tag>: the tag of the published base, platform, and converter images, such as 'dev'.
#
# Usage: bash ./.github/scripts/print-extension-settings.bash <extension-name> <core-ref> <image-tag>
#
# <extension-name>: Folder of the extension under test, or empty for the name of the repository that calls the workflow, read from 'GITHUB_REPOSITORY'.
# <core-ref>:       Branch or tag of the core that the workflow checks out, such as 'dev', 'main', or a release 'v3.0.0'.
# <image-tag>:      Tag of the published images, or empty for '<core-ref>' when it is 'dev', 'main', or a release 'vX.Y.Z', and for 'dev' otherwise, since the CI publishes no other tag.

################################################################################

# Name the extension under test, after the calling repository by default, and refuse anything but a plain folder name.
OPENROSDE_CI_EXTENSION_NAME="${1:-${GITHUB_REPOSITORY#*/}}"
if ! [[ "${OPENROSDE_CI_EXTENSION_NAME}" =~ ^[A-Za-z0-9_.-]+$ ]] || [ "${OPENROSDE_CI_EXTENSION_NAME}" = "." ] || [ "${OPENROSDE_CI_EXTENSION_NAME}" = ".." ]; then
  echo "Error: The extension under test must be a folder name with letters, digits, and '_.-' alone, but it is '${OPENROSDE_CI_EXTENSION_NAME}'." >&2
  exit 1
fi

# Name the tag of the published images, the one given or else the one that matches the version of the core, and refuse anything but a tag of Docker.
OPENROSDE_CI_IMAGE_TAG="$3"
if [ -z "${OPENROSDE_CI_IMAGE_TAG}" ]; then
  if [[ "$2" =~ ^(dev|main|v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    OPENROSDE_CI_IMAGE_TAG="$2"
  else
    OPENROSDE_CI_IMAGE_TAG="dev"
  fi
fi
if ! [[ "${OPENROSDE_CI_IMAGE_TAG}" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]]; then
  echo "Error: The tag of the images must be a tag of Docker, such as 'dev' or 'v3.0.0', but it is '${OPENROSDE_CI_IMAGE_TAG}'." >&2
  exit 1
fi

################################################################################

echo "extension-name=${OPENROSDE_CI_EXTENSION_NAME}"
echo "image-tag=${OPENROSDE_CI_IMAGE_TAG}"
