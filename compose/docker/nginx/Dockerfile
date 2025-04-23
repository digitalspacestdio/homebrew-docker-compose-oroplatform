FROM nginx:1.27

# Customization of the nginx user and group ids in the image. It's 101:101 in
# the base image. Here we use 33 which is the user id and group id for www-data
# on Ubuntu, Debian, etc.
ARG nginx_uid=1000
ARG nginx_gid=1000
ARG APP_DIR=/var/www
ENV APP_DIR=${APP_DIR}

# The worker processes in the nginx image run as the user nginx with group
# nginx. This is where we override their respective uid and guid to something
# else that lines up better with file permissions.
# The -o switch allows reusing an existing user id
RUN usermod -u $nginx_uid -o www-data && groupmod -g $nginx_gid -o www-data
ADD nginx.conf /etc/nginx/nginx.conf
RUN sed -i "s|/var/www|$APP_DIR|g" /etc/nginx/nginx.conf
