#!/usr/bin/env bash

set -e
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            deploy)    deploy=${VALUE} ;; # 发布环境
            tag)       tag=${VALUE} ;; # 发布TGA 默认 latest
            project)   project=${VALUE} ;; # project name
            *)
    esac

done

if [[ "$deploy" != "stg" && "$deploy" != "pro" ]]; then
    echo ">>> Please input DEPOLY=[stg | pro]"
    exit 1
fi

if [[ "$project" == "" ]]; then
    echo ">>> Please input project=[your project name]"
    exit 1
fi


if [[ "$tag" == "" ]]; then
    tag="latest"
fi

# Docker Registry Addr
registry_domain="test.com"

# Image Name
name=$project-$deploy

echo ">>> Building Binary"
docker run  -i --rm -e "GOPATH=/go" -v "$(pwd)":/go/src/$project --privileged -w /go/src/$project  golang:latest bash -c 'go get && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a --installsuffix cgo --ldflags="-s" -o app'

echo ">>> Upx Binary"
upx app

echo ">>> Copying Dockerfile"
if [[ -e Dockerfile ]]; then
    rm Dockerfile
fi
sudo cp $(dirname "$0")/Dockerfile ./

echo ">>> Building New Image"
docker build --no-cache -t $registry_domain/$name:$tag -f Dockerfile .

echo ">>> Push Docker Image"
docker login $registry_domain -u=username -p=password
docker push $registry_domain/$name:$tag

echo ">>> Stopping old container"
if [[ "$(docker ps -aq -f name=$name)" ]]; then
    docker stop $name
    docker rm -f $name
fi

echo ">>> Cleaning Up Images"
docker images | grep "<none>" | awk '{ print $3 }' | while read -r id ; do
  docker rmi -f $id
done

