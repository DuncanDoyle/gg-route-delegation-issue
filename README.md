# Gloo Gateway 1.17 - Kubernetes Gateway API

## Installation

Set the GLOO_GATEWAY_LICENSE_KEY environment variable with your license key.

```
export GLOO_GATEWAY_LICENSE_KEY={your-gloo-gateway-license-key}
```

Install Gloo Gateway:
```
cd install
./install-gloo-gateway-with-helm.sh
```

> [!NOTE]
> The Gloo Gateway version that will be installed is set in a variable at the top of the `install/install-gloo-edge-enterprise-with-helm.sh` installation script.


The script will install the Gloo Gateway control plane and create a K8S Gateway API gateway-proxy in the `ingress-gw` namespace.

Next, the `setup.sh` script to deploy the applications and `HttpRoute`s for the "httpbin" and "tracks" applicatiions.


# Reproducer


## HTTPBin

The HTTPBin example has 2 `HttpRoute`s
- `routes/httpbin-example-com-root-httproute.yaml`: this is the root HttpRoute that binds to the Gateway and delegates to the child
- `routes/httpbin-child-httproute.yaml`: this the child HttpRoute that routes to the HTTPBin service.

The issue is the following. The root `HttpRoute` only has a matcher for the path `/httpbin/v1.0/`, and for that match, it delegates to the child. The child has 2 matchers, one for `/httpbin/v1.0/`, which matches the matcher of the root, and one for `/random/` (but this could be any string). That second match, `/random/`, for which there is no equivalent in the parent is causing the issue. What it does is that it creates a matcher on `/` in Envoy for the `backendRef` it's referencing.

What this means is that with this configuration I can now access this HTTPBin app on paths:

```
curl -v http://httpbin.example.com/httpbin/v1.0/get
```
is the expected endpoint and works, but I can also access the httpbin app on this path:

```
curl -v http://httpbin.example.com/get
```
which should not be possible as we don't do any matching on `/` in the root routetable.


## Tracks API

The second example uses the Tracks API and consists of 3 `HttpRoute`s:
- `routes/api-example-com-root-httproute.yaml`: the root route that routes to the child route.
- `routes/tracks-apiproduct-httproute.yaml`: the child route that routes to the grandchild route.
- `routes/tracks-httproute.yaml`: the grandchild route that routes to tracks api service.

This example has the exact same problem due to the matcher on `/random/` in the grandchild route. The reason for adding this example is to show that we also need to take the use-case into account where there are multiple levels of delegation, simply because it's possible to define such a configuration.


# Conclusion

This is actually a serious poblem, as `HttpRoute` delegation is oftenly used to separate concerns and responsibilities between platform teams (root route) and application teams (child route). What this issue means is that application teams can now control the path on which their application is exposed through the gateway by simply adding a random matcher in the child `HttpRoute`.

