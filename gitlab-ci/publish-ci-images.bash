#!/bin/bash

# This script publishes the images of the pipeline under the name of its branch, 'dev' or 'main', by retagging them on the registry without downloading them.
# The registry keeps only the 'dev' and 'main' tags, and its cleanup policy removes the tags of the pipelines after a few days.
#
# Usage: bash ./gitlab-ci/publish-ci-images.bash <tag> <image-name> [<image-name> ...]
#
# <tag>:        Tag to publish, 'dev' or 'main'.
# <image-name>: Names of the images under '${CI_REGISTRY_IMAGE}', such as 'sde-base' and 'ur5e-devel'.

################################################################################

# Refuse any tag other than 'dev' and 'main', which are the only ones the registry keeps.
if [ "$1" != "dev" ] && [ "$1" != "main" ]; then
  echo "Error: Only 'dev' and 'main' are published, not '$1'."
  exit 1
fi

################################################################################

# Retag every image of the pipeline.
for SDE_CI_IMAGE_NAME in "${@:2}"; do
  echo "Publishing '${CI_REGISTRY_IMAGE}/${SDE_CI_IMAGE_NAME}:$1'..."
  docker buildx imagetools create \
    --tag "${CI_REGISTRY_IMAGE}/${SDE_CI_IMAGE_NAME}:$1" \
    "${CI_REGISTRY_IMAGE}/${SDE_CI_IMAGE_NAME}:pipeline-${CI_PIPELINE_ID}" || exit 1
done
