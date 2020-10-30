#!/bin/bash
set -eo pipefail

set +e
CNB_USER=heroku
(cat /etc/shadow | grep ${CNB_USER} > /dev/null) || {
  CNB_USER=cnb
}
set -e

export CNB_APP_DIR=/workspace
export CNB_CACHE_DIR=/cache
export CNB_LAYERS_DIR=/layers
export CNB_GROUP_PATH=${CNB_LAYERS_DIR}/group.toml
export CNB_PLAN_PATH=${CNB_LAYERS_DIR}/plan.toml
export CNB_REPORT_PATH=${CNB_LAYERS_DIR}/report.toml
export CNB_ANALYZED_PATH=${CNB_LAYERS_DIR}/analyzed.toml
export CNB_PROJECT_METADATA_PATH=${CNB_LAYERS_DIR}/project-metadata.toml

rm -rf ${CNB_APP_DIR}/*
mkdir -p ${CNB_LAYERS_DIR}
mkdir -p $(pwd)${CNB_LAYERS_DIR}
mkdir -p ${CNB_CACHE_DIR}
shopt -s dotglob
set +e
mv $(pwd)${CNB_APP_DIR}/* ${CNB_APP_DIR}
cp -r $(pwd)${CNB_CACHE_DIR}/* ${CNB_CACHE_DIR}
set -e
if [ "${CNB_REGISTRY_AUTH}" = "" ];then
  export CNB_REGISTRY_AUTH="{\"$(echo ${DOCKER_IMAGE} | awk -F '/' '{print $1}')\":\"Basic $(echo -n ${DOCKER_USERNAME}:${DOCKER_PASSWORD} | base64)\"}"
fi

chown -R ${USER_ID}:${GROUP_ID} ${CNB_APP_DIR}
chown -R ${USER_ID}:${GROUP_ID} ${CNB_LAYERS_DIR}
chown -R ${USER_ID}:${GROUP_ID} $(pwd)${CNB_LAYERS_DIR}
chown -R ${USER_ID}:${GROUP_ID} ${CNB_CACHE_DIR}

set -x
su --preserve-environment -c "/lifecycle/creator ${DOCKER_IMAGE}" ${CNB_USER} | tee creator.log
set +x
set +e
DIGEST=$(grep ' Digest:' creator.log | grep 'Digest' | sed 's/.*Digest: sha256://')
if [ "${DIGEST}" = "" ];then
  DIGEST=$(grep '(sha256' creator.log | sed 's/.*sha256://' | sed 's/)://')
fi
set -e
echo "${DIGEST}" >> ./image/digest
echo "sha256:${DIGEST}" | tee ./image/image-id
rm -rf $(pwd)${CNB_CACHE_DIR}/*
mv ${CNB_CACHE_DIR}/* $(pwd)${CNB_CACHE_DIR}