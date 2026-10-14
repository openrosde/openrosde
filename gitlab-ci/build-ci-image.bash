#!/bin/bash

# This script builds one Docker image of the SDE in the CI and pushes it with the tag of the pipeline, or reuses an identical image already in the registry.
# An image is identical when its label 'com.coarobo.sde.source-hash' matches the hash of the folders it is built from, so an unchanged image is retagged on the registry without being built or downloaded.
# Every job hands its image to the next ones through the registry only, so the pipeline runs the same on a self-managed runner and on the instance runners of GitLab.com.
#
# Usage: bash ./gitlab-ci/build-ci-image.bash <image-name> <dockerfile> <source-dirs> [<build-arg>=<value> ...]
#
# <image-name>:  Name of the image under '${CI_REGISTRY_IMAGE}', such as 'sde-base' or 'ur5e-devel'.
# <dockerfile>:  Path of the Dockerfile, relative to the repository root, which is the build context.
# <source-dirs>: Comma-separated folders whose content defines the image, such as 'docker/sde-base,docker/ur5e-devel'.
# <build-arg>:   Build arguments passed to 'docker buildx build'.

################################################################################

# Name the image, its tag in this pipeline, and the hash of its sources.
SDE_CI_IMAGE_NAME="${CI_REGISTRY_IMAGE}/$1"
SDE_CI_PIPELINE_TAG="pipeline-${CI_PIPELINE_ID}"

# Tag the images of a branch other than 'dev' and 'main' as 'branch-<branch>' too, so that the next pipeline of the branch reuses them, until the cleanup policy removes the tag a few days later.
if [ "${CI_COMMIT_REF_SLUG}" = "dev" ] || [ "${CI_COMMIT_REF_SLUG}" = "main" ]; then
  SDE_CI_BRANCH_TAG=""
else
  SDE_CI_BRANCH_TAG="branch-${CI_COMMIT_REF_SLUG}"
fi
SDE_CI_SOURCE_HASH="$(for SDE_CI_SOURCE_DIR in ${3//,/ }; do git rev-parse "HEAD:${SDE_CI_SOURCE_DIR}"; done | sha256sum | cut -c1-40)"
echo "Image '$1' from '$3' has the source hash '${SDE_CI_SOURCE_HASH}'."

################################################################################

# Reuse the image of the current branch, then of 'dev', then of 'main', if its source hash matches.
# 'docker buildx imagetools' reads only the manifest and the configuration from the registry, and retags on the registry itself.
for SDE_CI_CANDIDATE_TAG in ${SDE_CI_BRANCH_TAG} dev main; do
  SDE_CI_CANDIDATE_HASH="$(docker buildx imagetools inspect "${SDE_CI_IMAGE_NAME}:${SDE_CI_CANDIDATE_TAG}" --format '{{ index .Image.Config.Labels "com.coarobo.sde.source-hash" }}' 2>/dev/null)"
  if [ "${SDE_CI_CANDIDATE_HASH}" = "${SDE_CI_SOURCE_HASH}" ]; then
    echo "Reusing '${SDE_CI_IMAGE_NAME}:${SDE_CI_CANDIDATE_TAG}', whose sources are identical."
    docker buildx imagetools create --tag "${SDE_CI_IMAGE_NAME}:${SDE_CI_PIPELINE_TAG}" "${SDE_CI_IMAGE_NAME}:${SDE_CI_CANDIDATE_TAG}" || exit 1
    if [ -n "${SDE_CI_BRANCH_TAG}" ] && [ "${SDE_CI_CANDIDATE_TAG}" != "${SDE_CI_BRANCH_TAG}" ]; then
      docker buildx imagetools create --tag "${SDE_CI_IMAGE_NAME}:${SDE_CI_BRANCH_TAG}" "${SDE_CI_IMAGE_NAME}:${SDE_CI_PIPELINE_TAG}" || exit 1
    fi
    exit 0
  fi
done

################################################################################

# Collect the build arguments, and embed the commit hash of the Dockerfile for the version check of 'initialize-bash-shell.bash'.
SDE_CI_BUILD_ARGS=(--build-arg "SDE_DOCKERFILE_COMMIT_SHORT_SHA=$(git log -n 1 --pretty=format:%h -- "$2")")
for SDE_CI_BUILD_ARG in "${@:4}"; do
  SDE_CI_BUILD_ARGS+=(--build-arg "${SDE_CI_BUILD_ARG}")
done

# Build the image with the layers of the 'dev' and 'main' images as cache, which their inline cache makes usable, then push it with the tag of the pipeline.
echo "Building '${SDE_CI_IMAGE_NAME}:${SDE_CI_PIPELINE_TAG}'..."
docker buildx build \
  "${SDE_CI_BUILD_ARGS[@]}" \
  --cache-from "${SDE_CI_IMAGE_NAME}:dev" \
  --cache-from "${SDE_CI_IMAGE_NAME}:main" \
  --cache-to type=inline \
  --label "com.coarobo.sde.source-hash=${SDE_CI_SOURCE_HASH}" \
  --label "org.opencontainers.image.revision=${CI_COMMIT_SHA}" \
  --label "org.opencontainers.image.source=${CI_PROJECT_URL}" \
  --file "$2" \
  --tag "${SDE_CI_IMAGE_NAME}:${SDE_CI_PIPELINE_TAG}" \
  ${SDE_CI_BRANCH_TAG:+--tag "${SDE_CI_IMAGE_NAME}:${SDE_CI_BRANCH_TAG}"} \
  --push \
  .
