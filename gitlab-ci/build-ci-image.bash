#!/bin/bash

# This script builds one Docker image of OpenRoSDE in the CI and pushes it with the tag of the pipeline, or reuses an identical image already in the registry.
# An image is identical when its label 'com.coarobo.openrosde.source-hash' matches the hash of the folders it is built from, so an unchanged image is retagged on the registry without being built or downloaded.
# Every job hands its image to the next ones through the registry only, so the pipeline runs the same on a self-managed runner and on the instance runners of GitLab.com.
#
# Usage: bash ./gitlab-ci/build-ci-image.bash <image-name> <dockerfile> <source-dirs> [<build-arg>=<value> ...]
#
# <image-name>:  Name of the image under '${CI_REGISTRY_IMAGE}', such as 'openrosde-base' or 'ur5e-devel'.
# <dockerfile>:  Path of the Dockerfile, relative to the repository root, which is the build context.
# <source-dirs>: Comma-separated folders whose content defines the image, such as 'docker/openrosde-base,docker/ur5e-devel'.
# <build-arg>:   Build arguments passed to 'docker buildx build'.

################################################################################

# Name the image, its tag in this pipeline, and the hash of its sources.
OPENROSDE_CI_IMAGE_NAME="${CI_REGISTRY_IMAGE}/$1"
OPENROSDE_CI_PIPELINE_TAG="pipeline-${CI_PIPELINE_ID}"

# Name the tag 'branch-<slug>' of a branch, slugged as GitLab slugs 'CI_COMMIT_REF_SLUG'.
function openrosde-ci-branch-tag () {
  echo "branch-$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-63 | sed -e 's/^-*//' -e 's/-*$//')"
}

# Tag the images of a branch other than 'dev' and 'main' as 'branch-<branch>' too, so that the next pipeline of the branch reuses them, until the cleanup policy removes the tag a few days later.
if [ "${CI_COMMIT_REF_SLUG}" = "dev" ] || [ "${CI_COMMIT_REF_SLUG}" = "main" ]; then
  OPENROSDE_CI_BRANCH_TAG=""
else
  OPENROSDE_CI_BRANCH_TAG="branch-${CI_COMMIT_REF_SLUG}"
fi

# Name the tag of the target branch of a merge request, which 'OPENROSDE_CI_TARGET_BRANCH' gives, slugged as GitLab slugs a branch, so that a branch stacked on another starts from its images.
OPENROSDE_CI_TARGET_TAG=""
if [ -n "${OPENROSDE_CI_TARGET_BRANCH}" ] && [ "${OPENROSDE_CI_TARGET_BRANCH}" != "dev" ] && [ "${OPENROSDE_CI_TARGET_BRANCH}" != "main" ]; then
  OPENROSDE_CI_TARGET_TAG="$(openrosde-ci-branch-tag "${OPENROSDE_CI_TARGET_BRANCH}")"
fi

# Name the tag of the branch that a merge commit brings in, read from its message 'Merge branch '<branch>' into '<target>'', so that the pipeline of 'dev' after a merge reuses the images that the merge request already built.
OPENROSDE_CI_MERGED_TAG=""
OPENROSDE_CI_MERGED_BRANCH="$(echo "${CI_COMMIT_MESSAGE}" | sed -n "1s/^Merge branch '\([^']*\)' into .*/\1/p")"
if [ -n "${OPENROSDE_CI_MERGED_BRANCH}" ]; then
  OPENROSDE_CI_MERGED_TAG="$(openrosde-ci-branch-tag "${OPENROSDE_CI_MERGED_BRANCH}")"
fi
OPENROSDE_CI_SOURCE_HASH="$(for OPENROSDE_CI_SOURCE_DIR in ${3//,/ }; do git rev-parse "HEAD:${OPENROSDE_CI_SOURCE_DIR}"; done | sha256sum | cut -c1-40)"
echo "Image '$1' from '$3' has the source hash '${OPENROSDE_CI_SOURCE_HASH}'."

################################################################################

# Reuse the image of the current branch, then of the target branch of the merge request, then of the merged branch, then of 'dev', then of 'main', if its source hash matches.
# 'docker buildx imagetools' reads only the manifest and the configuration from the registry, and retags on the registry itself.
for OPENROSDE_CI_CANDIDATE_TAG in ${OPENROSDE_CI_BRANCH_TAG} ${OPENROSDE_CI_TARGET_TAG} ${OPENROSDE_CI_MERGED_TAG} dev main; do
  OPENROSDE_CI_CANDIDATE_HASH="$(docker buildx imagetools inspect "${OPENROSDE_CI_IMAGE_NAME}:${OPENROSDE_CI_CANDIDATE_TAG}" --format '{{ index .Image.Config.Labels "com.coarobo.openrosde.source-hash" }}' 2>/dev/null)"
  if [ "${OPENROSDE_CI_CANDIDATE_HASH}" = "${OPENROSDE_CI_SOURCE_HASH}" ]; then
    echo "Reusing '${OPENROSDE_CI_IMAGE_NAME}:${OPENROSDE_CI_CANDIDATE_TAG}', whose sources are identical."
    docker buildx imagetools create --tag "${OPENROSDE_CI_IMAGE_NAME}:${OPENROSDE_CI_PIPELINE_TAG}" "${OPENROSDE_CI_IMAGE_NAME}:${OPENROSDE_CI_CANDIDATE_TAG}" || exit 1
    if [ -n "${OPENROSDE_CI_BRANCH_TAG}" ] && [ "${OPENROSDE_CI_CANDIDATE_TAG}" != "${OPENROSDE_CI_BRANCH_TAG}" ]; then
      docker buildx imagetools create --tag "${OPENROSDE_CI_IMAGE_NAME}:${OPENROSDE_CI_BRANCH_TAG}" "${OPENROSDE_CI_IMAGE_NAME}:${OPENROSDE_CI_PIPELINE_TAG}" || exit 1
    fi
    exit 0
  fi
done

################################################################################

# Collect the build arguments, and embed the commit hash of the Dockerfile for the version check of 'initialize-bash-shell.bash'.
OPENROSDE_CI_BUILD_ARGS=(--build-arg "OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA=$(git log -n 1 --pretty=format:%h -- "$2")")
for OPENROSDE_CI_BUILD_ARG in "${@:4}"; do
  OPENROSDE_CI_BUILD_ARGS+=(--build-arg "${OPENROSDE_CI_BUILD_ARG}")
done

# Build the image with the layers of the 'dev' and 'main' images as cache, which their inline cache makes usable, then push it with the tag of the pipeline.
echo "Building '${OPENROSDE_CI_IMAGE_NAME}:${OPENROSDE_CI_PIPELINE_TAG}'..."
docker buildx build \
  "${OPENROSDE_CI_BUILD_ARGS[@]}" \
  --cache-from "${OPENROSDE_CI_IMAGE_NAME}:dev" \
  --cache-from "${OPENROSDE_CI_IMAGE_NAME}:main" \
  --cache-to type=inline \
  --label "com.coarobo.openrosde.source-hash=${OPENROSDE_CI_SOURCE_HASH}" \
  --label "org.opencontainers.image.revision=${CI_COMMIT_SHA}" \
  --label "org.opencontainers.image.source=${CI_PROJECT_URL}" \
  --file "$2" \
  --tag "${OPENROSDE_CI_IMAGE_NAME}:${OPENROSDE_CI_PIPELINE_TAG}" \
  ${OPENROSDE_CI_BRANCH_TAG:+--tag "${OPENROSDE_CI_IMAGE_NAME}:${OPENROSDE_CI_BRANCH_TAG}"} \
  --push \
  .
