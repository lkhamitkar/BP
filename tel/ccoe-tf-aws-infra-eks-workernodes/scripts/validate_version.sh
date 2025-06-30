#!/bin/bash
git fetch
EXAMPLE_TAG=$(cat ${CI_PROJECT_DIR}/${EXAMPLE_NODEGROUP_FOLDER}/main.tf | grep 'source =' | cut -d "=" -f3 | sed 's/\"//' | tr -d \\n)

echo "Example version is ${EXAMPLE_TAG}";

CLVERSION=$(grep "##" CHANGELOG.md -m 1 | cut -d " " -f2)
echo "Changelog version is ${CLVERSION}"

if [[ $CLVERSION !=  $EXAMPLE_TAG ]]; then
    echo "Change log version does not match with example versions"
    exit 1
else
    echo "Changelog and TF versions Match!"
fi;

if git show-ref --tags | egrep -q "refs/tags/${EXAMPLE_TAG}" >/dev/null 2>&1; then
    echo "tag already exists"
    if [[ ! -z $CI_MERGE_REQUEST_ID ]]; then
        exit 1
    fi;
else
    echo "The tag ${EXAMPLE_TAG} does not exist, continuing."
    sed -i "s/${EXAMPLE_TAG}/${CI_COMMIT_SHA}/" ${CI_PROJECT_DIR}/${EXAMPLE_NODEGROUP_FOLDER}/main.tf
    sed -i "s/${EXAMPLE_TAG}/${CI_COMMIT_SHA}/" ${CI_PROJECT_DIR}/${EXAMPLE_SPOTINSTANCES_FOLDER}/main.tf
fi;