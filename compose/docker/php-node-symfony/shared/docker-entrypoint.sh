#!/bin/bash
set -e

# Remove .orodc.marker file if it exists (created on host to preserve ownership of empty directories)
# This marker file is created on the host before container startup to prevent Docker
# from showing empty directories as root-owned inside the container
# NOTE: Marker removal is now handled by orodc on the host after containers start
# if [[ -f "${APP_DIR:-/var/www}/.orodc.marker" ]]; then
#   rm -f "${APP_DIR:-/var/www}/.orodc.marker" 2>/dev/null || true
# fi

#OWNER_UID=$(stat -c '%u' ${APP_DIR:-/var/www})
#OWNER_GID=$(stat -c '%g' ${APP_DIR:-/var/www})

# usermod -u $OWNER_UID -o www-data && groupmod -g $OWNER_GID -o www-data

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

if [[ -f /.zshrc ]]; then
	rm -f ${PHP_USER_HOME}/.zshrc
	cp /.zshrc ${PHP_USER_HOME}/.zshrc
	cat >> ${PHP_USER_HOME}/.zshrc <<- EOM

		cd \${APP_DIR:-/var/www}
	EOM
fi

if [[ $XDEBUG_MODE = "off" ]]; then
	rm -f "${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini" 2>/dev/null || true
	rm -f "${PHP_INI_DIR}/conf.d/app.xdebug.ini" 2>/dev/null || true
fi

# Generate msmtprc configuration based on ORO_MAILER_ENCRYPTION
# Default is starttls if not specified
if [[ "${ORO_MAILER_ENCRYPTION:-}" == "none" ]]; then
	template="/msmtprc-none.tmpl"
elif [[ "${ORO_MAILER_ENCRYPTION:-}" == "tls" ]]; then
	template="/msmtprc-tls.tmpl"
elif [[ "${ORO_MAILER_ENCRYPTION:-}" == "starttls" ]] || [[ -z "${ORO_MAILER_ENCRYPTION:-}" ]] || [[ "${ORO_MAILER_ENCRYPTION:-}" == "" ]]; then
	template="/msmtprc-starttls.tmpl"
else
	# Default to starttls if unknown value
	template="/msmtprc-starttls.tmpl"
fi

if [[ -f "$template" ]]; then
	cp "$template" /.msmtprc
	if [[ -n "${DEBUG:-}" ]]; then
		echo "DEBUG: Generated /.msmtprc from $template (ORO_MAILER_ENCRYPTION=${ORO_MAILER_ENCRYPTION:-starttls})" >&2
	fi
else
	echo "WARNING: msmtprc template $template not found, using default" >&2
	# Fallback to starttls config
	cat > /.msmtprc <<- EOM
account default
host mail
port 1025
tls on
tls_starttls on
tls_trust_file /certs/mail.crt
tls_certcheck off
auth off
from www-data@localhost
EOM
fi

chmod +x ${PHP_USER_HOME}/.profile

export PHP_IDE_CONFIG="serverName=$(hostname | cut -d. -f2-)"

exec docker-php-entrypoint "$@"