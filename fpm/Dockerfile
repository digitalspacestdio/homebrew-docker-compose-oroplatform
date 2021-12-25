FROM digitalspacestudio/php:8.0
USER root
RUN apt update && apt install -yqq build-essential systemtap-sdt-dev make uuid-runtime
USER linuxbrew
RUN brew install node@14
RUN brew link --overwrite node@14
