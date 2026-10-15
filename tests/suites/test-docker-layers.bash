#!/bin/bash

# This suite checks the Docker layers of extensions, which build locally between the platform image and the user overlay, under 'openrosde-local/<setup>/' rather than the registry.
# It uses the platform extension 'foo', whose platform image is no layer, the device 'bar' with a layer, and the setup 'my-lab-foo-bench' with a layer of its own.
#
# Usage: bash ./tests/run.bash test-docker-layers

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
OPENROSDE_TEST_REGISTRY="registry.gitlab.com/coarobo/sde"
OPENROSDE_TEST_FOO_DIR="extensions/openrosde-platform-foo"
OPENROSDE_TEST_BAR_DIR="extensions/openrosde-device-bar"
OPENROSDE_TEST_LAB_DIR="extensions/my-lab"
OPENROSDE_TEST_SETUP_NAME="my-lab-foo-bench"
OPENROSDE_TEST_LOCAL_PREFIX="openrosde-local/${OPENROSDE_TEST_SETUP_NAME}"

# Create the platform 'foo' with its image, the device 'bar' with a layer, and the setup with a layer.
openrosde-test-create-extension openrosde-platform-foo
openrosde-test-write-platform-template "${OPENROSDE_TEST_FOO_DIR}" foo
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/docker/foo-devel/Dockerfile" "FROM scratch"
openrosde-test-create-extension openrosde-device-bar
openrosde-test-write-file "${OPENROSDE_TEST_BAR_DIR}/docker/bar-devel/Dockerfile" "ARG OPENROSDE_PARENT_IMAGE" 'FROM ${OPENROSDE_PARENT_IMAGE}'
openrosde-test-create-extension my-lab
openrosde-test-write-setup-template "${OPENROSDE_TEST_LAB_DIR}" "${OPENROSDE_TEST_SETUP_NAME}" foo "openrosde-device-bar"
openrosde-test-write-file "${OPENROSDE_TEST_LAB_DIR}/docker/${OPENROSDE_TEST_SETUP_NAME}-devel/Dockerfile" "ARG OPENROSDE_PARENT_IMAGE" 'FROM ${OPENROSDE_PARENT_IMAGE}'

# Name the build commands of the two layers.
OPENROSDE_TEST_BAR_BUILD="docker build --build-arg OPENROSDE_PARENT_IMAGE=${OPENROSDE_TEST_REGISTRY}/foo-devel:dev --build-arg OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA=abc1234 -f ./${OPENROSDE_TEST_BAR_DIR}/docker/bar-devel/Dockerfile -t ${OPENROSDE_TEST_LOCAL_PREFIX}/bar-devel:latest ./${OPENROSDE_TEST_BAR_DIR}"
OPENROSDE_TEST_LAB_BUILD="docker build --build-arg OPENROSDE_PARENT_IMAGE=${OPENROSDE_TEST_LOCAL_PREFIX}/bar-devel:latest --build-arg OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA=abc1234 -f ./${OPENROSDE_TEST_LAB_DIR}/docker/${OPENROSDE_TEST_SETUP_NAME}-devel/Dockerfile -t ${OPENROSDE_TEST_LOCAL_PREFIX}/${OPENROSDE_TEST_SETUP_NAME}-devel:latest ./${OPENROSDE_TEST_LAB_DIR}"

################################################################################

# Check a platform of the core, which has no layer.
openrosde-test-select-template env/ur5e.env
openrosde-test-check "builds no layer for a platform of the core" \
  "$(printf '%s\n' "layers: " "user-parent: ${OPENROSDE_TEST_REGISTRY}/ur5e-devel:dev")" \
  "$(openrosde-test-print-paths | grep -E '^(layers|user-parent):')"

# Check the layers of the setup.
openrosde-test-select-template "${OPENROSDE_TEST_LAB_DIR}/env/${OPENROSDE_TEST_SETUP_NAME}.env"
openrosde-test-check "stacks the layer of the device, then of the setup, and never the platform image" \
  "./${OPENROSDE_TEST_BAR_DIR}/docker/bar-devel/Dockerfile ./${OPENROSDE_TEST_LAB_DIR}/docker/${OPENROSDE_TEST_SETUP_NAME}-devel/Dockerfile" \
  "$(openrosde-test-print-path layers)"
openrosde-test-check "builds the user overlay on the last layer, under the local prefix of the setup" \
  "$(printf '%s\n' "user-parent: ${OPENROSDE_TEST_LOCAL_PREFIX}/${OPENROSDE_TEST_SETUP_NAME}-devel:latest" "local-prefix: ${OPENROSDE_TEST_LOCAL_PREFIX}")" \
  "$(openrosde-test-print-paths | grep -E '^(user-parent|local-prefix):')"
openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash local
openrosde-test-check "builds each layer from its folder on top of the previous image" \
  "$(printf '%s\n' "${OPENROSDE_TEST_BAR_BUILD}" "${OPENROSDE_TEST_LAB_BUILD}")" \
  "$(openrosde-test-print-calls | grep '^docker build')"
openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "pulls the images, then builds the layers and the user overlay by default" \
  "$(printf '%s\n' \
    "docker compose -p test -f ./docker/docker-compose.yaml pull openrosde-base" \
    "docker compose -p test -f ./docker/docker-compose.yaml pull openrosde-mesh2glb" \
    "docker compose -p test -f ./docker/docker-compose.yaml pull openrosde-platform" \
    "${OPENROSDE_TEST_BAR_BUILD}" \
    "${OPENROSDE_TEST_LAB_BUILD}" \
    "docker compose -p test -f ./docker/docker-compose.yaml build openrosde")" \
  "$(openrosde-test-print-calls | grep -E '^docker (compose|build) ')"
OPENROSDE_TEST_FAILING_CALL="bar-devel/Dockerfile" openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "stops before the user overlay when a layer fails to build" \
  "1 failed to build no-user-overlay" \
  "${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -o -m 1 'failed to build') $(openrosde-test-print-calls | grep -q 'build openrosde$' || echo no-user-overlay)"
OPENROSDE_TEST_FAILING_CALL="bar-devel/Dockerfile" openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash local
openrosde-test-check "stops before the user overlay when a layer fails to build in the 'local' mode" \
  "1 failed to build no-user-overlay" \
  "${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -o -m 1 'failed to build') $(openrosde-test-print-calls | grep -q 'build openrosde$' || echo no-user-overlay)"

################################################################################

# Check the shared script of the layers, sourced after the loader on another parent image, as a CI job sources it.
openrosde-test-run bash -c 'source ./scripts/load-openrosde-env.bash test > /dev/null 2>&1 && source ./scripts/build-extension-layers.bash ubuntu:20.04'
openrosde-test-check "builds the layers on the parent image given to 'scripts/build-extension-layers.bash'" \
  "$(printf '%s\n' "0" "${OPENROSDE_TEST_BAR_BUILD/${OPENROSDE_TEST_REGISTRY}\/foo-devel:dev/ubuntu:20.04}" "${OPENROSDE_TEST_LAB_BUILD}")" \
  "$(printf '%s\n' "${OPENROSDE_TEST_EXIT_CODE}"; openrosde-test-print-calls | grep '^docker build')"
openrosde-test-run bash -c 'source ./scripts/load-openrosde-env.bash test > /dev/null 2>&1 && source ./scripts/build-extension-layers.bash'
openrosde-test-check "refuses to build the layers without a parent image" \
  "1 Usage: source ./scripts/build-extension-layers.bash <parent-image>" \
  "${OPENROSDE_TEST_EXIT_CODE} ${OPENROSDE_TEST_OUTPUT}$(openrosde-test-print-calls | grep '^docker build')"

################################################################################

# Check that a second setup, held by another extension, that shares the layer of the device tags it apart, so that neither setup overwrites the image of the other.
openrosde-test-create-extension other-lab
openrosde-test-write-setup-template extensions/other-lab other-lab-foo-cart foo "openrosde-device-bar"
openrosde-test-select-template extensions/other-lab/env/other-lab-foo-cart.env
openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash local
openrosde-test-check "tags the shared layer of the device under the local prefix of each setup" \
  "$(printf '%s\n' "-t openrosde-local/other-lab-foo-cart/bar-devel:latest" "user-parent: openrosde-local/other-lab-foo-cart/bar-devel:latest")" \
  "$(openrosde-test-print-calls | grep '^docker build' | grep -o -- '-t [^ ]*'; openrosde-test-print-paths | grep '^user-parent:')"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
