#!/usr/bin/env bash
cd `dirname $0`/..

set -e

IMAGE_NAME=eu.gcr.io/${PROJECT_ID}/gckb-example
IMAGE_TAG=${IMAGE_NAME}:$1
CLUSTER_NAME=gckb-example
COMP_ZONE=europe-west1-d

gcloud docker -- tag $IMAGE_NAME $IMAGE_TAG
gcloud docker -- push $IMAGE_TAG

# currently accessing k8s is not possible out of the box due to secrets handling
# this pulls credentials from a private google bucket and uses them to deploy
# the new image in favour of the base service account credentials

gsutil cp gs://${CREDS_BUCKET_NAME}/creds.json /tmp
gcloud --quiet auth activate-service-account --key-file=/tmp/creds.json

gcloud --quiet config set project ${PROJECT_ID}
gcloud --quiet config set container/cluster ${CLUSTER_NAME}
gcloud --quiet config set compute/zone ${COMP_ZONE}
gcloud --quiet container clusters get-credentials ${CLUSTER_NAME}
kubectl patch deployment django -p'{"spec":{"template":{"spec":{"containers":[{"name":"django","image":"${IMAGE_TAG}"}]}}}}'
