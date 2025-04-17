#!/bin/bash
set -x
[ -f /etc/ssh/hostkeys/ssh_host_rsa_key ] || ssh-keygen -t rsa -f /etc/ssh/hostkeys/ssh_host_rsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ecdsa_key ] || ssh-keygen -t ecdsa -f /etc/ssh/hostkeys/ssh_host_ecdsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -f /etc/ssh/hostkeys/ssh_host_ed25519_key -N ''; \
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_rsa_key/a HostKey /etc/ssh/hostkeys/ssh_host_rsa_key' /etc/ssh/sshd_config
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/a HostKey /etc/ssh/hostkeys/ssh_host_ecdsa_key' /etc/ssh/sshd_config
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_ed25519_key/a HostKey /etc/ssh/hostkeys/ssh_host_ed25519_key' /etc/ssh/sshd_config
echo 'AcceptEnv COMPOSER_AUTH' | tee -a /etc/ssh/sshd_config
echo 'PermitUserEnvironment yes' | tee -a /etc/ssh/sshd_config

if [[ -n $ORO_SSH_PUBLIC_KEY ]]; then
	mkdir -p /root/.ssh
	echo "${ORO_SSH_PUBLIC_KEY}" > /root/.ssh/authorized_keys
	chmod -R 0600 /root/.ssh

	if [[ -n $PHP_UID ]]; then
		PHP_USER_HOME=$(eval echo "~$PHP_USER_NAME")
		mkdir -p ${PHP_USER_HOME}/.ssh
		echo "${ORO_SSH_PUBLIC_KEY}" > ${PHP_USER_HOME}/.ssh/authorized_keys
		chmod 0700 ${PHP_USER_HOME}/.ssh
		chmod -R 0600 ${PHP_USER_HOME}/.ssh/*
		chown -R "${PHP_USER_NAME}" ${PHP_USER_HOME}
		usermod -s /bin/bash $PHP_USER_NAME
		usermod -p '*' $PHP_USER_NAME

		# cat > ${PHP_USER_HOME}/.profile <<- EOM
		# cd ${APP_DIR:-/var/www}
		# EOM

		# chmod +x "${PHP_USER_HOME}/.profile"
		
		cat >> /etc/ssh/sshd_config <<- EOM
		Match User ${PHP_USER_NAME}
			AllowTcpForwarding yes
			PermitTunnel yes
			GatewayPorts yes
		#	ForceCommand bash -c 'if [ -n "$SSH_ORIGINAL_COMMAND" ]; then exec "$SSH_ORIGINAL_COMMAND"; else cd ${APP_DIR:-/var/www} && exec bash; fi'
		EOM

		# Load docker env variables
		printenv | while IFS='=' read -r name value; do
			if echo "$name" | grep -v '^\(HOME\|PWD\)' > /dev/null; then
  				echo "$name=$value"
			fi
		done > "${PHP_USER_HOME}/.ssh/environment"
		chown "${PHP_UID}" "${PHP_USER_HOME}/.ssh/environment"
		chmod 600 "${PHP_USER_HOME}/.ssh/environment"

		if [[ -d "${APP_DIR:-/var/www}/.git" ]]; then
			su - $PHP_USER_NAME -c 'git config --global --add safe.directory "'${APP_DIR:-/var/www}'/.git"'
		fi
	fi
fi

chmod 0777 ${APP_DIR:-/var/www}
if [[ -d "${APP_DIR:-/var/www}/.git" ]]; then
	git config --global --add safe.directory "${APP_DIR:-/var/www}/.git"
fi

exec /usr/sbin/sshd -D -e