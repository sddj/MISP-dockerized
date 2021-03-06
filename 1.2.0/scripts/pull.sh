#!/bin/sh
set -eu

docker run \
    -ti \
    --name misp-robot-init \
    --rm \
    --network="host" \
    -v "$PWD":/srv/MISP-dockerized \
    -v ~/.docker:/root/.docker:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    "$(grep DOCKER_REGISTRY "$PWD/config/config.env"|cut -d = -f 2)"/misp-dockerized-robot:"$(grep ROBOT_CONTAINER_TAG "$PWD"/config/config.env|cut -d = -f 2)" \
        bash -c \
            "docker-compose -f /srv/MISP-dockerized/docker-compose.yml -f /srv/MISP-dockerized/docker-compose.override.yml pull "
    #$(cat $(CURDIR)/config/config.env|grep DOCKER_REGISTRY|cut -d = -f 2)/misp-dockerized-robot:$(shell cat $(CURDIR)/config/config.env|grep ROBOT_CONTAINER_TAG|cut -d = -f 2) bash -c "docker-compose -f /srv/MISP-dockerized/docker-compose.yml -f /srv/MISP-dockerized/docker-compose.override.yml pull "