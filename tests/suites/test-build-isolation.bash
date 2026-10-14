#!/bin/bash

# This suite checks how the images are pulled and built, and what the entry scripts and the container shell print.
# It covers the images that 'OPENROSDE_DOCKER_BUILD_FALLBACK' lets 'BUILD-DOCKER-IMAGE.bash' build when a pull fails, the tag that 'auto' derives from the checkout, the local names of a setup, the values that the loader never prints, the version of the core that a setup pins, and the version check of the container shell.
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
openrosde-test-check "derives 'main' on 'main' and on any detached checkout, even of a release, whose images the registry does not hold, and 'dev' elsewhere" \
  "$(printf '%s\n' "main: main" "dev: dev" "feat/foo:v3.1.0 dev" "HEAD:v3.1.0 main" "HEAD:v3.1.0-rc.1 main" "HEAD:v3.1 main" "HEAD: main")" \
  "${OPENROSDE_TEST_TAG_REPORT%$'\n'}"
openrosde-test-check "builds the user overlay on the 'main' platform image on a detached checkout of a release" \
  "user-parent: registry.gitlab.com/coarobo/sde/ur5e-devel:main" \
  "$(OPENROSDE_TEST_GIT_BRANCH=HEAD OPENROSDE_TEST_GIT_TAG=v3.1.0 openrosde-test-print-paths | grep '^user-parent:')"

################################################################################

# Check the local names of a setup whose name holds uppercase letters, which a Docker repository name refuses, with a layer named after it, and of a setup that Docker refuses even in lowercase.
openrosde-test-create-extension my-lab
openrosde-test-write-setup-template extensions/my-lab My-Lab-UR5e-Bench ur5e ""
openrosde-test-write-file extensions/my-lab/docker/My-Lab-UR5e-Bench-devel/Dockerfile "ARG OPENROSDE_PARENT_IMAGE" 'FROM ${OPENROSDE_PARENT_IMAGE}'
openrosde-test-select-template extensions/my-lab/env/My-Lab-UR5e-Bench.env
openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash local
openrosde-test-check "lowercases the setup and its layer in the local names, with no error" \
  "$(printf '%s\n' "user-parent: openrosde-local/my-lab-ur5e-bench/my-lab-ur5e-bench-devel:latest" "local-prefix: openrosde-local/my-lab-ur5e-bench" "-t openrosde-local/my-lab-ur5e-bench/my-lab-ur5e-bench-devel:latest" "errors 0")" \
  "$(openrosde-test-print-paths | grep -E '^(user-parent|local-prefix):'; openrosde-test-print-calls | grep '^docker build ' | grep -o ' -t [^ ]*' | cut -c2-; echo "errors $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c '^Error:')")"
openrosde-test-write-setup-template extensions/my-lab my-lab.-ur5e ur5e ""
openrosde-test-select-template extensions/my-lab/env/my-lab.-ur5e.env
openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
openrosde-test-check "reports a setup whose name Docker refuses even in lowercase" \
  "Error: Setup 'my-lab.-ur5e' cannot name its local Docker images, since Docker takes letters and digits separated by one '.', one or two '_', or dashes." \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:')"
rm -rf "${OPENROSDE_TEST_ROOT_DIR}/extensions/my-lab"

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

# Check the version of the image that the shell of the container prints, with its commit held by the repository of the platform or not, as for a platform outside the core.
# The shell reads the settings of the copy, with the TurtleBot3 selected, where the stubbed 'git' answers all the same.
openrosde-test-select-template env/turtlebot3.env
for OPENROSDE_TEST_COMMIT_MISSING in false true; do
  OPENROSDE_TEST_GIT_COMMIT_MISSING="${OPENROSDE_TEST_COMMIT_MISSING}" openrosde-test-run bash -c 'export OPENROSDE_CONTAINER_ROOT_DIR="${PWD}" OPENROSDE_DOCKER_IMAGE_VERSION=def5678; source ./docker/openrosde-base/scripts/initialize-bash-shell.bash'
  OPENROSDE_TEST_SHELL_REPORT="${OPENROSDE_TEST_SHELL_REPORT}missing ${OPENROSDE_TEST_COMMIT_MISSING}: $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -E '^(Container version|Newer image available):' | tr '\n' '|')"$'\n'
done
openrosde-test-check "compares the image with the latest Dockerfile only when the repository of the platform holds its commit" \
  "$(printf '%s\n' "missing false: Container version: turtlebot3-devel:def5678 from Mon Oct 12 09:00:00 2026 +0900|Newer image available: turtlebot3-devel:abc1234 from abc1234|" "missing true: Container version: turtlebot3-devel:def5678|")" \
  "${OPENROSDE_TEST_SHELL_REPORT%$'\n'}"

# Check that the shell of the container exports the settings to the scripts it runs, as the CI does, but keeps the functions of the loader to itself.
openrosde-test-select-template env/ur5e.env
openrosde-test-run bash -c 'export OPENROSDE_CONTAINER_ROOT_DIR="${PWD}" OPENROSDE_DOCKER_IMAGE_VERSION=def5678; source ./docker/openrosde-base/scripts/initialize-bash-shell.bash > /dev/null 2>&1; bash -c "echo \"settings: \${OPENROSDE_ROBOT_PLATFORM} \${OPENROSDE_ROBOT_SETUP} \${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}\""; echo "exported functions: $(env | grep -c "^BASH_FUNC_openrosde")"; echo "own functions: $(type -t openrosde-find-setup-file)"'
openrosde-test-check "exports the settings of the setup from the shell of the container, and no function of the loader" \
  "$(printf '%s\n' "settings: ur5e ur5e ${OPENROSDE_TEST_ROOT_DIR}" "exported functions: 0" "own functions: function")" \
  "${OPENROSDE_TEST_OUTPUT}"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
