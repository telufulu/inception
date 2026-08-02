# Instalation Alpine OS
FROM alpine:3.22

# Install NGINX and OpenSSL
RUN apk update && apk add --no-cache nginx openssl

# Copy the NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Create TLS directories and generate a self-signed certificate
RUN mkdir -p /etc/ssl/private /etc/ssl/certs && \
	openssl req -x509 -nodes -days 365 \
	-newkey rsa:2048 \
	-keyout /etc/ssl/private/inception.key \
	-out /etc/ssl/certs/inception.crt \
	-subj "/CN=telufulu.42.fr"

# Start NGINX in foreground as the main container process
CMD ["nginx", "-g", "daemon off;"]
