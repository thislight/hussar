#! /bin/sh
if [ ! $DOCKER ]; then DOCKER="podman"; fi

$DOCKER push $1:debian11_lua53
$DOCKER push $1:debian11_lua53_git
$DOCKER push $1:alpine3d12_lua54
$DOCKER push $1:alpine3d12_lua54_git
