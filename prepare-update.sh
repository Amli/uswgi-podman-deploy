#!/bin/env sh

IMAGE=uwsgi-basic
VERSION=$1

# podman pull uwsgi-basic:version-$VERSION
podman build -t $IMAGE:version-$VERSION --build-arg VERSION=$VERSION -f Dockerfile .
podman tag $IMAGE:current $IMAGE:previous
podman tag $IMAGE:version-$VERSION $IMAGE:current

echo "ready to rollout $IMAGE:version-$VERSION"