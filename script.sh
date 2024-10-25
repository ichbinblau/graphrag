#!/bin/bash
# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -e
IMAGE_REPO=${IMAGE_REPO:-"opea"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}
echo "REGISTRY=IMAGE_REPO=${IMAGE_REPO}"
echo "TAG=IMAGE_TAG=${IMAGE_TAG}"
export REGISTRY=${IMAGE_REPO}
export TAG=${IMAGE_TAG}

WORKPATH="$PWD"
LOG_PATH="$WORKPATH/tests"
host_ip=$(hostname -I | awk '{print $1}')

function build_docker_images() { 
    cp -fr $(dirname $WORKPATH)/ChatQnA/ui $WORKPATH
    cd $WORKPATH/docker_image_build
    #TODO update the main when components are merged
    #git clone https://github.com/opea-project/GenAIComps.git && cd GenAIComps && git checkout "${opea_branch:-"main"}" && cd ../
    rm -fr GenAIComps
    git clone https://github.com/rbrugaro/GenAIComps.git && cd GenAIComps && git checkout "${opea_branch:-"graphRAG_LI"}" && cd ../

    echo "Build all the images with --no-cache, check docker_image_build.log for details..."
    service_list="graphrag dataprep-neo4j-llamaindex retriever-neo4j-llamaindex chatqna-gaudi-ui-server chatqna-gaudi-nginx-server"
    docker compose -f build.yaml build ${service_list} --no-cache > ${LOG_PATH}/docker_image_build.log

    docker pull ghcr.io/huggingface/tgi-gaudi:2.0.5
    docker pull ghcr.io/huggingface/text-embeddings-inference:cpu-1.5
    docker pull neo4j:latest
    docker images && sleep 1s
}

function start_services() {
    cd $WORKPATH/docker_compose/intel/hpu/gaudi
    
    export http_proxy=${http_proxy}
    export https_proxy=${https_proxy}
    export no_proxy=${no_proxy}
    export NEO4J_PASSWORD=password 
    export EMBEDDING_MODEL_ID="BAAI/bge-base-en-v1.5"
    export LLM_MODEL_ID="meta-llama/Llama-3.1-70B-Instruct"
    export HUGGINGFACEHUB_API_TOKEN=${HUGGINGFACEHUB_API_TOKEN}
    export TEI_EMBEDDING_ENDPOINT="http://${host_ip}:6006"
    export TGI_LLM_ENDPOINT="http://${host_ip}:6005"
    export NEO4J_URL="bolt://${host_ip}:7687"
    export NEO4J_USERNAME=neo4j
    export DATAPREP_SERVICE_ENDPOINT="http://${host_ip}:6004/v1/dataprep"
    export LOGFLAG=True
    export RETRIEVER_SERVICE_PORT=6009
    #this will need to be updated with the set_env variables and how about the required from private????

    # Start Docker Containers
    docker compose -f compose.yaml up -d > ${LOG_PATH}/start_services_with_compose.log

    n=0
    until [[ "$n" -ge 100 ]]; do
        docker logs tgi-gaudi-server > ${LOG_PATH}/tgi_service_start.log
        if grep -q Connected ${LOG_PATH}/tgi_service_start.log; then
            break
        fi
        sleep 5s
        n=$((n+1))
    done
}

function stop_docker() {
    cd $WORKPATH/docker_compose/intel/hpu/gaudi
    docker compose  -f compose.yaml stop && docker compose -f compose.yaml rm -f
}

function main() {

    stop_docker
    if [[ "$IMAGE_REPO" == "opea" ]]; then build_docker_images; fi
    start_time=$(date +%s)
    start_services
    end_time=$(date +%s)
    duration=$((end_time-start_time))
    echo "Mega service start duration is $duration s"
}

main
