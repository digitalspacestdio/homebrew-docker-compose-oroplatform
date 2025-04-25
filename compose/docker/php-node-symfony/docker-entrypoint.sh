#!/bin/bash
set -e

# OWNER_UID=$(stat -c '%u' /var/www)
# OWNER_GID=$(stat -c '%g' /var/www)

# usermod -u $nginx_uid -o www-data && groupmod -g $nginx_gid -o www-data

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

if [[ -d "${APP_DIR:-/var/www}/.git" ]]; then
	git config --global --add safe.directory "${APP_DIR:-/var/www}/.git"
fi
PHP_USER_HOME=$(eval echo "~$PHP_USER_NAME")
cat > ${PHP_USER_HOME}/.profile <<- EOM
	cd \${APP_DIR:-/var/www}
EOM

#JBR_VERSION="jbr-21.0.5"
#JBR_BUILD="b631.28"
JAVA_HOME=${PHP_USER_HOME}/.java

if [[ -n ${JBR_VERSION} ]] && [[ -n ${JBR_BUILD} ]] && [[ ! -d ${JAVA_HOME} ]]; then
 	ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) JBR_ARCH="x64";; \
        aarch64) JBR_ARCH="aarch64";; \
        *) echo "Unsupported arch: $ARCH" && exit 1;; \
    esac && \
    JBR_URL="https://cache-redirector.jetbrains.com/intellij-jbr/${JBR_VERSION}-linux-musl-${JBR_ARCH}-${JBR_BUILD}.tar.gz" && \
    echo "Downloading JBR from $JBR_URL" && \
    mkdir -p ${JAVA_HOME} && \
    curl -fSL "$JBR_URL" -o /tmp/jbr.tar.gz && \
    tar -xzf /tmp/jbr.tar.gz -C ${JAVA_HOME} --strip-components=1 && \
    rm /tmp/jbr.tar.gz
fi

if [[ -f ${JAVA_HOME}/bin/java ]]; then
	cat > /etc/profile.d/java.sh <<- EOM
		export JAVA_HOME=${JAVA_HOME}
		export PATH="\${JAVA_HOME}/bin:\${PATH}"
	EOM
	if [[ ! -e /usr/bin/java ]]; then
		ln -f -s ${JAVA_HOME}/bin/java /usr/bin/java
	fi
fi

if [[ -f /.zshrc ]]; then
	rm -f ${PHP_USER_HOME}/.zshrc
	cp /.zshrc ${PHP_USER_HOME}/.zshrc
	cat >> ${PHP_USER_HOME}/.zshrc <<- EOM

		cd \${APP_DIR:-/var/www}
	EOM
fi
chmod +x ${PHP_USER_HOME}/.profile

exec docker-php-entrypoint "$@"