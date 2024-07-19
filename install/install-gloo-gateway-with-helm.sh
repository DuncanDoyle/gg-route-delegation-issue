#!/bin/sh

source ./env.sh


if [ -z "$GLOO_GATEWAY_LICENSE_KEY" ]
then
   echo "Gloo Gateway License Key not specified. Please configure the environment variable 'GLOO_EDGE_LICENSE_KEY' with your Gloo Edge License Key."
   exit 1
fi

#----------------------------------------- Install Gloo Gateway with K8S Gateway API support -----------------------------------------

printf "\nApply K8S Gateway CRDs ....\n"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

printf "\nInstalling Gloo Gateway $GLOO_GATEWAY_VERSION ...\n"
helm upgrade --install gloo glooe/gloo-ee  --namespace gloo-system --create-namespace --set-string license_key=$GLOO_GATEWAY_LICENSE_KEY -f $GLOO_GATEWAY_HELM_VALUES_FILE --version $GLOO_GATEWAY_VERSION
printf "\n"

pushd ../
#----------------------------------------- Deploy the Gateway -----------------------------------------

# create the ingress-gw namespace
kubectl create namespace ingress-gw --dry-run=client -o yaml | kubectl apply -f -

printf "\nDeploy the Gateway ...\n"
kubectl apply -f gateways/gw.yaml

popd
