#!/bin/bash

# This script publishes the images of the pipeline under the name of its branch, 'dev' or 'main', or of its release tag, 'vX.Y.Z', by retagging them on the registry without downloading them.
# The cleanup policy of the registry keeps the tags it publishes, and removes the tags of the pipelines after a few days.
#
# Usage: bash ./gitlab-ci/publish-ci-images.bash <tag> <image-name> [<image-name> ...]
#
# <tag>:        Tag to publish, 'dev', 'main', or a release 'vX.Y.Z', such as 'v3.0.0'.
# <image-name>: Names of the images under '${CI_REGISTRY_IMAGE}', such as 'openrosde-base' and 'ur5e-devel'.

################################################################################

# Refuse any tag other than 'dev', 'main', and a release 'vX.Y.Z', which are the only ones the registry keeps.
if [ "$1" != "dev" ] && [ "$1" != "main" ] && ! [[ "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Only 'dev', 'main', and a release 'vX.Y.Z' are published, not '$1'."
  exit 1
fi

################################################################################

# Retag every image of the pipeline.
for OPENROSDE_CI_IMAGE_NAME in "${@:2}"; do
  echo "Publishing '${CI_REGISTRY_IMAGE}/${OPENROSDE_CI_IMAGE_NAME}:$1'..."
  docker buildx imagetools create \
    --tag "${CI_REGISTRY_IMAGE}/${OPENROSDE_CI_IMAGE_NAME}:$1" \
    "${CI_REGISTRY_IMAGE}/${OPENROSDE_CI_IMAGE_NAME}:pipeline-${CI_PIPELINE_ID}" || exit 1
done
