FROM alpine:3.12

ARG USERNAME=proxy_user
ARG USER_UID=2001
ARG USER_GID=${USER_UID}

COPY rproxy.conf /etc/nginx/rproxy.template
COPY startup.sh /etc/nginx/startup.sh

RUN apk add --no-cache \
  curl \
  gettext \
  nginx \
  openssl

# Create user and group to run nginx
RUN addgroup --gid $USER_GID $USERNAME \
  && adduser --system --shell /bin/ash -u $USER_UID -G $USERNAME $USERNAME \
  # Link nginx logs to STDOUT / STDERR
  && ln -s /dev/stdout /var/log/nginx/access.log \
  && ln -s /dev/stderr /var/log/nginx/error.log \
  # Remove the default configuration file
  && rm /etc/nginx/conf.d/default.conf \
  # Remove the nginx user from nginx config
  && sed -i -e '/user/!b' -e '/nginx/!b' -e '/nginx/d' /etc/nginx/nginx.conf \
  # Move nginx pid file location to /var/run folder
  && sed -i 's!/var/run/nginx.pid!/tmp/nginx.pid!g' /etc/nginx/nginx.conf \
  # Move temp path locations to /tmp
  && sed -i "/^http {/a \ proxy_temp_path /tmp/proxy_temp;\n client_body_temp_path /tmp/client_temp;\n fastcgi_temp_path /tmp/fastcgi_temp;\n uwsgi_temp_path /tmp/uwsgi_temp;\n scgi_temp_path /tmp/scgi_temp;\n" /etc/nginx/nginx.conf \
  # change permissions on nginx and var folders
  && mkdir -p /run/nginx/ \
  && chown ${USER_UID}:0 /run/nginx \
  && touch /run/nginx/nginx.pid \
  && chown ${USER_UID}:0 /run/nginx/nginx.pid \
  && chown ${USER_UID}:0 /var/lib/nginx \
  && chmod 775 /var/lib/nginx \
  && chown ${USER_UID}:0 /etc/nginx/conf.d \
  && chmod 775 /etc/nginx/conf.d \
  && chown ${USER_UID}:0 /etc/nginx/rproxy.template \
  && chmod 770 /etc/nginx/rproxy.template \
  && chown ${USER_UID}:0 /etc/nginx/startup.sh \
  && chmod 770 /etc/nginx/startup.sh \
  && chown ${USER_UID}:0 /etc/ssl/certs \
  && chown ${USER_UID}:0 /etc/ssl/private \
  && chmod 770 /etc/ssl/private

ENV DNS_RESOLVER=127.0.0.11 \
  HTTP_PORT=8080 \
  HTTPS_PORT=8443 \
  PROXY_PROTO=http \
  PROXY_UPSTREAM=codeandkeep.com \
  SITE_NAME=proxy.codeandkeep.com

USER $USERNAME

ENTRYPOINT ["/bin/sh", "/etc/nginx/startup.sh"]
