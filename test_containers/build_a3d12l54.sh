#! /bin/sh
if [ ! $DOCKER ]; then DOCKER="podman"; fi

podman build -t registry.gitlab.com/thislight/hussar:alpine3d12_lua54 test_containers/alpine3d12_lua54
