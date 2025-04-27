#!/bin/bash
set -x
[ -f /etc/ssh/sshd_config.backup ] && cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config || cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
[ -f /etc/ssh/hostkeys/ssh_host_rsa_key ] || ssh-keygen -t rsa -f /etc/ssh/hostkeys/ssh_host_rsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ecdsa_key ] || ssh-keygen -t ecdsa -f /etc/ssh/hostkeys/ssh_host_ecdsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -f /etc/ssh/hostkeys/ssh_host_ed25519_key -N ''; \
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_rsa_key/a HostKey /etc/ssh/hostkeys/ssh_host_rsa_key' /etc/ssh/sshd_config
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/a HostKey /etc/ssh/hostkeys/ssh_host_ecdsa_key' /etc/ssh/sshd_config
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_ed25519_key/a HostKey /etc/ssh/hostkeys/ssh_host_ed25519_key' /etc/ssh/sshd_config
echo 'AcceptEnv COMPOSER_AUTH' | tee -a /etc/ssh/sshd_config
echo 'PermitTTY yes' | tee -a /etc/ssh/sshd_config
echo 'PermitUserEnvironment yes' | tee -a /etc/ssh/sshd_config
echo 'AllowAgentForwarding yes' | tee -a /etc/ssh/sshd_config

if [[ -n $ORO_SSH_PUBLIC_KEY ]]; then
	mkdir -p /root/.ssh
	echo "${ORO_SSH_PUBLIC_KEY}" > /root/.ssh/authorized_keys
	chmod -R 0600 /root/.ssh
	if which zsh; then
		chsh -s $(which zsh) $USER
	fi

	if [[ -n $PHP_UID ]]; then
		PHP_USER_HOME=$(eval echo "~$PHP_USER_NAME")
		mkdir -p ${PHP_USER_HOME}/.ssh
		echo "${ORO_SSH_PUBLIC_KEY}" > ${PHP_USER_HOME}/.ssh/authorized_keys
		chmod 0700 ${PHP_USER_HOME}/.ssh
		chmod -R 0600 ${PHP_USER_HOME}/.ssh/*
		chown -R "${PHP_USER_NAME}" ${PHP_USER_HOME}
		usermod -s /bin/bash $PHP_USER_NAME
		usermod -p '*' $PHP_USER_NAME
		
		cat >> /etc/ssh/sshd_config <<- EOM
		Match User ${PHP_USER_NAME}
			AllowAgentForwarding yes
			AllowTcpForwarding yes
			PermitTunnel yes
			GatewayPorts yes
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

		if which zsh; then
			chsh -s $(which zsh) $PHP_USER_NAME
		fi

		chown ${PHP_UID}:${PHP_GID} ${APP_DIR:-/var/www}

		if [[ -d ${PHP_USER_HOME}/.cache/JetBrains ]]; then
			JBR_VERSION="jbr-21.0.5"
			JBR_BUILD="b631.28"
			JAVA_HOME=${PHP_USER_HOME}/.java

			if [[ -n ${JBR_VERSION} ]] && [[ -n ${JBR_BUILD} ]] && [[ ! -e ${JAVA_HOME}/bin/java ]]; then
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
				cat >> ${PHP_USER_HOME}/.profile <<- EOM
					export JAVA_HOME=${JAVA_HOME}
				EOM

				cat >> "${PHP_USER_HOME}/.ssh/environment" <<- EOM
					JAVA_HOME=${JAVA_HOME}
				EOM

				cat >> ${PHP_USER_HOME}/.zshrc <<- EOM
					if ! echo $PATH | egrep egrep '[^[:alnum:]_]${JAVA_HOME}/bin[^[:alnum:]_]' > /dev/null; then
						export PATH="${JAVA_HOME}/bin:\${PATH}"
					fi
				EOM
			fi

			rm -rf rm -rf ${PHP_USER_HOME}/.cache/JetBrains/RemoteDev/dist/*/jbr
		fi
	fi
fi

# if [[ -d "${APP_DIR:-/var/www}/.git" ]]; then
# 	git config --global --add safe.directory "${APP_DIR:-/var/www}/.git"
# fi

if [[ -d "${APP_DIR:-/var/www}/var/cache" ]]; then
	rm -rf "${APP_DIR:-/var/www}/var/cache/*"
fi

exec /usr/sbin/sshd -D -e