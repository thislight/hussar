#! /bin/sh
if [ ! $DOCKER ]; then DOCKER="podman"; fi

$DOCKER build -t registry.gitlab.com/thislight/hussar:debian11_lua53 test_containers/debian11_lua53
