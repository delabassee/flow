#!/bin/bash
set -ex

user="fnproject"
service="flow"
tag="latest"

# ensure working dir is clean
git status
if [[ -z $(git status -s) ]]
then
  echo "tree is clean"
else
  echo "tree is dirty, please commit changes before running this"
  exit 1
fi

git pull

version_file="version/version.go"
if [ -z $(grep -m1 -Po '(?<= = ")\d+\.\d+\.\d+' $version_file) ]; then
  echo "did not find semantic version in $version_file"
  exit 1
fi
perl -i -pe 's/(?<= = ")\d+\.\d+\.\K(\d+)/$1+1/e' $version_file
version=$(grep -m1 -Po '(?<= = ")\d+\.\d+\.\d+' $version_file)
echo "Version: $version"

make docker-build

git add $version_file
git commit -m "$service: $version release [skip ci]"
git tag -f -a "$version" -m "version $version"
git push
git push origin $version

# Finally tag and push docker images
docker tag $user/$service:$tag $user/$service:$version
docker push $user/$service:$version
docker push $user/$service:$tag
