#!/bin/sh

pushd ..

kubectl label namespaces default --overwrite shared-gateway-access="true"

# Create httpbin namespace if it does not exist yet
kubectl create namespace httpbin --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f apis/httpbin/httpbin.yaml

kubectl apply -f routes/httpbin-example-com-root-httproute.yaml
kubectl apply -f routes/httpbin-child-httproute.yaml

kubectl create namespace tracks --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f apis/tracks/tracks-api-1.0.yaml

kubectl apply -f routes/api-example-com-root-httproute.yaml
kubectl apply -f routes/tracks-apiproduct-httproute.yaml
kubectl apply -f routes/tracks-httproute.yaml

popd

