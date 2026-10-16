#!/bin/bash

# This script runs a script of 'gitlab-ci/' in a job of GitHub Actions, with the variables of GitLab CI that the scripts read set from those of GitHub Actions, so that both CI systems run the same scripts.
# The registry of the images is 'OPENROSDE_CI_REGISTRY_IMAGE', which the workflow sets in one place, such as 'ghcr.io/openrosde', and the ID of the run stands for the ID of the pipeline, so a run pushes its images as 'pipeline-<run-id>', which every attempt of the run shares.
# The branch or tag of the run is slugged as GitLab slugs 'CI_COMMIT_REF_SLUG', and the message of its commit is read from the checkout, so that 'gitlab-ci/build-ci-image.bash' tags and reuses the images as it does on GitLab.
# 'OPENROSDE_CI_IMAGE_REGISTRY' and 'OPENROSDE_CI_IMAGE_TAG', where the test jobs read the images, keep a value that the workflow sets, and default to the images of the run.
#
# Usage: bash ./.github/scripts/run-gitlab-ci-script.bash <script> [<argument> ...]
#
# <script>:   Script of 'gitlab-ci/' to run, such as './gitlab-ci/build-ci-image.bash'.
# <argument>: Arguments of that script.

################################################################################

# Check that this runs in a job of GitHub Actions, with the registry named.
if [ -z "${GITHUB_RUN_ID}" ] || [ -z "${OPENROSDE_CI_REGISTRY_IMAGE}" ]; then
  echo "Error: This script runs in a job of GitHub Actions, with 'OPENROSDE_CI_REGISTRY_IMAGE' set to the registry of the images, such as 'ghcr.io/openrosde'."
  exit 1
fi
if [ ! -f "$1" ]; then
  echo "Error: The script '$1' does not exist."
  exit 1
fi

################################################################################

# Set the variables of GitLab CI that the scripts of 'gitlab-ci/' read.
export CI_REGISTRY_IMAGE="${OPENROSDE_CI_REGISTRY_IMAGE}"
export CI_PIPELINE_ID="${GITHUB_RUN_ID}"
export CI_COMMIT_SHA="${GITHUB_SHA}"
export CI_COMMIT_REF_NAME="${GITHUB_REF_NAME}"
export CI_PROJECT_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
CI_COMMIT_REF_SLUG="$(echo "${GITHUB_REF_NAME}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-63 | sed -e 's/^-*//' -e 's/-*$//')"
export CI_COMMIT_REF_SLUG
CI_COMMIT_MESSAGE="$(git log -n 1 --pretty=format:%B HEAD 2> /dev/null)"
export CI_COMMIT_MESSAGE

# Read the images of the run, unless the workflow names others.
export OPENROSDE_CI_IMAGE_REGISTRY="${OPENROSDE_CI_IMAGE_REGISTRY:-${CI_REGISTRY_IMAGE}}"
export OPENROSDE_CI_IMAGE_TAG="${OPENROSDE_CI_IMAGE_TAG:-pipeline-${CI_PIPELINE_ID}}"

################################################################################

# Run the script with its arguments.
exec bash "$@"
