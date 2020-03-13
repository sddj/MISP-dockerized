#!/bin/sh

docker run \
    -ti \
    --name misp-robot-init \
    --rm \
    --network="host" \
    -v $PWD:/srv/MISP-dockerized \
    -v ~/.docker:/root/.docker:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    $(cat $PWD/config/config.env|grep DOCKER_REGISTRY|cut -d = -f 2)/misp-dockerized-robot:$(cat $PWD/config/config.env|grep ROBOT_CONTAINER_TAG|cut -d = -f 2) bash -c "cd /srv/MISP-dockerized && docker-compose pull"
    #$(cat $(CURDIR)/config/config.env|grep DOCKER_REGISTRY|cut -d = -f 2)/misp-dockerized-robot:$(shell cat $(CURDIR)/config/config.env|grep ROBOT_CONTAINER_TAG|cut -d = -f 2) bash -c "cd /srv/MISP-dockerized && docker-compose pull"
