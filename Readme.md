# Nginx Reverse Proxy (non-root)

## Description
----

A simple Nginx based reverse proxy.

Uses a base Alpine Linux image, 
and adds the requirements to run Nginx as a non-root user.

### SSL

The container will be configured with HTTPS on port 8443 (HTTP port 8080).

By default, incoming HTTP traffic will be redirected to HTTPS.
The default proxy protocol however, is HTTP.

This means that communication between the client and the proxy is over HTTPS,
but traffic to the upstream server(s) by default is HTTP.
This can be customized using the `PROXY_PROTO` environment variable 
(see examples below).

#### Certificates

At startup, the container will check a default location for a certificate.
If no certificate is found, a self-signed certificate will be generated.

The default locations are as follows:
- Certificate path: `/etc/ssl/certs/$SITE_NAME.crt`
- Certificate key path: `/etc/ssl/private/$SITE_NAME.key`

The name of the certificate / key, 
is determined by the `SITE_NAME` environment variable.

For example, `SITE_NAME=codeandkeep.com`:
- Certificate path: `/etc/ssl/certs/codeandkeep.com.crt`
- Certificate key path: `/etc/ssl/private/codeandkeep.com.key`

The recommended approach to using custom certificates,
is to mount certificates from the host to the container 
at these specific paths (see examples below).

### DNS
Be default, the internal Docker DNS service will be used (127.0.0.11).
To use a custom DNS server, use the `DNS_RESOLVER` environment variable 
(see examples below).


## Docker pull

```bash
docker image pull briansworth/nginx_rproxy:alpine
```

## Examples

Simple example using a custom DNS resolver, 
and exposing 80 and 443 on the host to the default container ports.

```bash
docker container run -p 80:8080 \
  -p 443:8443 \
  -e DNS_RESOLVER=8.8.4.4 \
  briansworth/nginx_rproxy:alpine
```

*NOTE: This will require generation of Diffie Hellman parameters which nginx will use for security purposes.*
*It can take a long time to generate.*
*See example below for how to get around this wait.*


Example that mounts the dhparam.pem file from the host, inside the container.
Avoids having to generate when starting the container (which is very slow).

```bash
# Assumes /etc/ssl/certs/dhparam.pem exists on the host
docker container run -p 443:8443 \
  -v /etc/ssl/certs/dhparam.pem:/etc/ssl/certs/dhparam.pem \
  -e DNS_RESOLVER=8.8.4.4 \
  briansworth/nginx_rproxy:alpine
```

Example to set where the proxy will point to (`PROXY_UPSTREAM`).

```bash
docker container run -p 443:8443 \
  -v /etc/ssl/certs/dhparam.pem:/etc/ssl/certs/dhparam.pem \
  -e PROXY_UPSTREAM=web_container:8443 \
  -e SITE_NAME=mysite.local \
  briansworth/nginx_rproxy:alpine
```

Example to customize the upstream protocol (`PROXY_PROTO`).

```bash
docker container run -p 443:8443 \
  -v /etc/ssl/certs/dhparam.pem:/etc/ssl/certs/dhparam.pem \
  -e PROXY_PROTO=https \
  -e PROXY_UPSTREAM=www.codeandkeep.com \
  -e DNS_RESOLVER=1.1.1.1 \
  briansworth/nginx_rproxy:alpine
```

Example of mounting the certificate / key from the host to the container.

```bash
DNS_NAME=proxy.codeandkeep.com
docker container run -p 443:8443 \
  -v /etc/ssl/certs/dhparam.pem:/etc/ssl/certs/dhparam.pem \
  -v $(pwd)/$DNS_NAME.crt:/etc/ssl/certs/$DNS_NAME.crt \
  -v $(pwd)/$DNS_NAME.key:/etc/ssl/private/$DNS_NAME.key \
  -e SITE_NAME=$DNS_NAME \
  -e DNS_RESOLVER=1.1.1.1 \
  -e PROXY_PROTO=https \
  -e PROXY_UPSTREAM=codeandkeep.com \
  briansworth/nginx_rproxy:alpine
```

## Docker Compose

The included `docker-compose.yml` is an example of using this Docker image.
It leverages a Jekyll demo container that will be used as the `PROXY_UPSTREAM`.

### Example

```bash
# The jekyll container takes a while (~1 min) to come up fully
docker-compose up
```

Navigate to `http://localhost` to verify.
It will by default redirect http -> https. 
Additionally, it will generate a self-signed certificate, 
so the browser will warn about the risk of going to this website.
