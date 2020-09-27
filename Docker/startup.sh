PROXY_TEMP='/etc/nginx/rproxy.template'
PROXY_CONF='/etc/nginx/conf.d/rproxy.conf'
CERT_PATH="/etc/ssl/certs/$SITE_NAME.crt"
CERT_KEY_PATH="/etc/ssl/private/$SITE_NAME.key"
DHPARAM_PATH="/etc/ssl/certs/dhparam.pem"
DHPARAM_SIZE=3096

envsubst '$DNS_RESOLVER,$HTTP_PORT,$HTTPS_PORT,$PROXY_PROTO,$PROXY_UPSTREAM,$SITE_NAME' < $PROXY_TEMP > $PROXY_CONF

if [ ! -f $CERT_PATH ]; then
  echo "Creating self-signed certificate: [$CERT_PATH]"
  openssl req -new -newkey rsa:4096 -nodes -days 60 -x509 \
    -out $CERT_PATH \
    -keyout $CERT_KEY_PATH \
    -subj "/C=CA/ST=Ontario/L=Toronto/O=CodeAndKeep/CN=$SITE_NAME"
fi

if [ ! -f $DHPARAM_PATH ]; then
  echo "Generating DHParam [$DHPARAM_PATH] Size: [$DHPARAM_SIZE]"
  openssl dhparam -out $DHPARAM_PATH $DHPARAM_SIZE
fi

exec /usr/sbin/nginx -g 'daemon off;'
