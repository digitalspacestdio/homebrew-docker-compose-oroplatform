FROM nginx:1.28

# Customization of the nginx user and group ids in the image. It's 101:101 in
# the base image. Here we use 33 which is the user id and group id for www-data
# on Ubuntu, Debian, etc.
ARG nginx_uid=1000
ARG nginx_gid=1000
ARG APP_DIR=/var/www

# The worker processes in the nginx image run as the user nginx with group
# nginx. This is where we override their respective uid and guid to something
# else that lines up better with file permissions.
# The -o switch allows reusing an existing user id
RUN usermod -u $nginx_uid -o www-data && groupmod -g $nginx_gid -o www-data

# Copy both configs - universal is default, legacy kept for compatibility
COPY nginx-universal.conf /etc/nginx/nginx-universal.conf
COPY nginx-legacy.conf /etc/nginx/nginx-legacy.conf
COPY --chmod=0755 entrypoint.sh /usr/local/bin/nginx-entrypoint

# Default to universal config
ENV DC_ORO_NGINX_CONFIG=universal
ENV APP_DIR=${APP_DIR}

ENTRYPOINT ["nginx-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
