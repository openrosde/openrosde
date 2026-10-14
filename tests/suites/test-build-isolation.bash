#!/bin/bash

# This suite checks how the images are pulled and built, and what the entry scripts print.
# It covers the images that 'OPENROSDE_DOCKER_BUILD_FALLBACK' lets 'BUILD-DOCKER-IMAGE.bash' build when a pull fails, the tag that 'auto' derives from the checkout, the values that the loader never prints, and the version of the core that a setup pins.
#
# Usage: bash ./tests/run.bash test-build-isolation

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
OPENROSDE_TEST_COMPOSE_CALL="docker compose -p [a-z]* -f ./docker/docker-compose.yaml"

# Select the UR5e with a fallback mode, given as argument, in '.env.custom'.
function openrosde-test-select-fallback () {
  openrosde-test-select-template env/ur5e.env
  echo "OPENROSDE_DOCKER_BUILD_FALLBACK=$1" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
}

# Print the pulls and builds of the last run, then its status.
function openrosde-test-print-builds () {
  openrosde-test-print-calls | grep -E '^docker (compose|build) ' | sed "s#^${OPENROSDE_TEST_COMPOSE_CALL} ##"
  echo "status ${OPENROSDE_TEST_EXIT_CODE}"
}

################################################################################

# Check the images that a failed pull lets 'BUILD-DOCKER-IMAGE.bash' build.
openrosde-test-select-fallback true
OPENROSDE_TEST_FAILING_CALL=" pull " openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "builds the base and platform images when their pulls fail, by default" \
  "$(printf '%s\n' "pull openrosde-base" "build openrosde-base" "pull openrosde-platform" "build openrosde-platform" "build openrosde" "status 0")" \
  "$(openrosde-test-print-builds)"
openrosde-test-select-fallback false
OPENROSDE_TEST_FAILING_CALL="pull openrosde-base" openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "fails without building anything when the pull of the base fails with 'false'" \
  "$(printf '%s\n' "pull openrosde-base" "status 1" "Error: The pull of 'registry.gitlab.com/coarobo/sde/openrosde-base:dev' failed, and 'OPENROSDE_DOCKER_BUILD_FALLBACK=false' does not build it locally.")" \
  "$(openrosde-test-print-builds; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:')"
OPENROSDE_TEST_FAILING_CALL="pull openrosde-platform" openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "fails without building anything when the pull of the platform fails with 'false'" \
  "$(printf '%s\n' "pull openrosde-base" "pull openrosde-platform" "status 1")" \
  "$(openrosde-test-print-builds)"
openrosde-test-select-fallback platform
OPENROSDE_TEST_FAILING_CALL="pull openrosde-base" openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "fails without building the base when its pull fails with 'platform'" \
  "$(printf '%s\n' "pull openrosde-base" "status 1")" \
  "$(openrosde-test-print-builds)"
OPENROSDE_TEST_FAILING_CALL="pull openrosde-platform" openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "builds the platform image alone when its pull fails with 'platform'" \
  "$(printf '%s\n' "pull openrosde-base" "pull openrosde-platform" "build openrosde-platform" "build openrosde" "status 0")" \
  "$(openrosde-test-print-builds)"
openrosde-test-select-fallback yes
openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "refuses another fallback mode before calling Docker" \
  "$(printf '%s\n' "status 1" "Error: 'OPENROSDE_DOCKER_BUILD_FALLBACK' is 'yes', but it must be 'true', 'platform', or 'false'.")" \
  "$(openrosde-test-print-calls | grep '^docker '; echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:')"
openrosde-test-select-fallback false
openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash local
openrosde-test-check "builds every image in the 'local' mode, whatever the fallback mode" \
  "$(printf '%s\n' "build openrosde-base" "build openrosde-platform" "build openrosde" "status 0")" \
  "$(openrosde-test-print-builds)"

################################################################################

# Check the tag that 'OPENROSDE_DOCKER_IMAGE_TAG=auto' derives from the checkout of the core.
openrosde-test-select-template env/ur5e.env
OPENROSDE_TEST_TAG_REPORT=""
for OPENROSDE_TEST_CHECKOUT in "main:" "dev:" "feat/foo:v3.1.0" "HEAD:v3.1.0" "HEAD:v3.1.0-rc.1" "HEAD:v3.1" "HEAD:"; do
  OPENROSDE_TEST_TAG_REPORT="${OPENROSDE_TEST_TAG_REPORT}${OPENROSDE_TEST_CHECKOUT} $(OPENROSDE_TEST_GIT_BRANCH="${OPENROSDE_TEST_CHECKOUT%%:*}" OPENROSDE_TEST_GIT_TAG="${OPENROSDE_TEST_CHECKOUT#*:}" openrosde-test-print-path image-tag)"$'\n'
done
openrosde-test-check "derives 'main', 'dev', or the release of a detached checkout of exactly 'vX.Y.Z'" \
  "$(printf '%s\n' "main: main" "dev: dev" "feat/foo:v3.1.0 dev" "HEAD:v3.1.0 v3.1.0" "HEAD:v3.1.0-rc.1 main" "HEAD:v3.1 main" "HEAD: main")" \
  "${OPENROSDE_TEST_TAG_REPORT%$'\n'}"
openrosde-test-check "builds the user overlay on the platform image of the release on a detached checkout of its tag" \
  "user-parent: registry.gitlab.com/coarobo/sde/ur5e-devel:v3.1.0" \
  "$(OPENROSDE_TEST_GIT_BRANCH=HEAD OPENROSDE_TEST_GIT_TAG=v3.1.0 openrosde-test-print-paths | grep '^user-parent:')"

################################################################################

# Check the variables that the entry scripts print, with a password, a token, and a secret in '.env.custom'.
openrosde-test-select-template env/ur5e.env
printf '%s\n' "OPENROSDE_ROBOT_PASSWORD=hunter2" "OPENROSDE_REGISTRY_TOKEN=example-token-value" "OPENROSDE_API_SECRET=s3cr3t" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
openrosde-test-check "prints every variable, but never the value of a password, a token, or a secret" \
  "$(printf '%s\n' "./RUN-DOCKER-CONTAINER.bash: OPENROSDE_API_SECRET=<redacted>" "./RUN-DOCKER-CONTAINER.bash: OPENROSDE_REGISTRY_TOKEN=<redacted>" "./RUN-DOCKER-CONTAINER.bash: OPENROSDE_ROBOT_PASSWORD=<redacted>" "./RUN-DOCKER-CONTAINER.bash: OPENROSDE_ROBOT_PLATFORM=ur5e" "values 0")" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -E ': OPENROSDE_(API_SECRET|REGISTRY_TOKEN|ROBOT_PASSWORD|ROBOT_PLATFORM)='; echo "values $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -cE 'hunter2|example-token-value|s3cr3t')")"
echo "OPENROSDE_QUIET=true" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
openrosde-test-check "prints no variable with 'OPENROSDE_QUIET=true', and still runs the container" \
  "0 docker compose -p test -f ./docker/docker-compose.yaml -f ./docker/docker-compose-ur5e.yaml -f ./docker/docker-compose-user.yaml up -d openrosde" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c ': OPENROSDE_') $(openrosde-test-print-calls | grep '^docker compose')"

# Check that the loader no longer runs 'scripts/list-robot-platforms.bash', whose warnings every entry script printed, and reads the names that the templates declare instead.
openrosde-test-write-file scripts/list-robot-platforms.bash 'echo "list-robot-platforms" >> "${OPENROSDE_TEST_COMMAND_LOG}"'
openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
openrosde-test-check "runs no listing of the platforms when an entry script loads the settings" \
  "" \
  "$(openrosde-test-print-calls | grep '^list-robot-platforms')"
cp "${OPENROSDE_TEST_SOURCE_DIR}/scripts/list-robot-platforms.bash" "${OPENROSDE_TEST_ROOT_DIR}/scripts/list-robot-platforms.bash"

################################################################################

# Check the version of the core that a setup pins, with a setup of the UR5e in the extension 'my-lab'.
openrosde-test-create-extension my-lab
openrosde-test-write-setup-template extensions/my-lab my-lab-ur5e-bench ur5e ""
openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash my-lab-ur5e-bench
openrosde-test-check "warns about no version of the core when the setup pins none" \
  "0 " \
  "${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Warning:')"
echo "OPENROSDE_CORE_VERSION=v3.0.0" >> "${OPENROSDE_TEST_ROOT_DIR}/extensions/my-lab/env/my-lab-ur5e-bench.env"
OPENROSDE_TEST_GIT_BRANCH=HEAD OPENROSDE_TEST_GIT_TAG=v3.0.0 openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash my-lab-ur5e-bench
openrosde-test-check "warns about nothing when the core is checked out at the pinned tag" \
  "0 " \
  "${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Warning:')"
OPENROSDE_TEST_GIT_BRANCH=dev OPENROSDE_TEST_GIT_TAG=v2.12.0 openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash my-lab-ur5e-bench
openrosde-test-check "warns when the core is checked out at another version, and prints the checkout, but still switches" \
  "$(printf '%s\n' "0 same" "Warning: Setup 'my-lab-ur5e-bench' pins the core at 'v3.0.0', but the core is checked out at 'v2.12.0'." "Check out the pinned version, then switch again, with: git -C '.' checkout 'v3.0.0' && bash './SWITCH-ROBOT-SETUP.bash' 'my-lab-ur5e-bench'")" \
  "$(echo "${OPENROSDE_TEST_EXIT_CODE} $(cmp -s "${OPENROSDE_TEST_ROOT_DIR}/extensions/my-lab/env/my-lab-ur5e-bench.env" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" && echo same)"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -A 1 '^Warning:' | sed "s#${OPENROSDE_TEST_ROOT_DIR}#.#g")"
openrosde-test-write-setup-template extensions/my-lab my-lab-ur5e-bench ur5e ""
echo "OPENROSDE_CORE_VERSION=dev" >> "${OPENROSDE_TEST_ROOT_DIR}/extensions/my-lab/env/my-lab-ur5e-bench.env"
OPENROSDE_TEST_GIT_BRANCH=dev OPENROSDE_TEST_GIT_TAG='' openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash my-lab-ur5e-bench
openrosde-test-check "warns about nothing when the setup pins the checked out branch" \
  "0 " \
  "${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Warning:')"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
