#!/bin/bash

################################################################################

# Tag the Docker image with the Git short SHA associated to the latest 'Dockerfile' modification.
DOCKER_FILE_HASH=`git log -n 1 --no-merges --pretty=format:%h ../docker/sde-devel/Dockerfile`
docker tag registry.gitlab.com/coarobo/sde/sde-devel:latest registry.gitlab.com/coarobo/sde/sde-devel:${DOCKER_FILE_HASH}

# Authenticate with the Docker image registry on GitLab.
docker login registry.gitlab.com/coarobo/sde

# Push the latest Docker image in the registry.
docker push registry.gitlab.com/coarobo/sde/sde-devel:${DOCKER_FILE_HASH}
docker push registry.gitlab.com/coarobo/sde/sde-devel:latest
