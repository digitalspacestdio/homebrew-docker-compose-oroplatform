#!/bin/bash
set -ex
[ -f /etc/ssh/hostkeys/ssh_host_rsa_key ] || ssh-keygen -t rsa -f /etc/ssh/hostkeys/ssh_host_rsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ecdsa_key ] || ssh-keygen -t ecdsa -f /etc/ssh/hostkeys/ssh_host_ecdsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -f /etc/ssh/hostkeys/ssh_host_ed25519_key -N ''; \
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_rsa_key/a HostKey /etc/ssh/hostkeys/ssh_host_rsa_key' /etc/ssh/sshd_config
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/a HostKey /etc/ssh/hostkeys/ssh_host_ecdsa_key' /etc/ssh/sshd_config
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_ed25519_key/a HostKey /etc/ssh/hostkeys/ssh_host_ed25519_key' /etc/ssh/sshd_config

if [[ -n $ORO_SSH_PUBLIC_KEY ]]; then
	mkdir -p /root/.ssh
	echo "${ORO_SSH_PUBLIC_KEY}" > /root/.ssh/authorized_keys
	chmod -R 0600 /root/.ssh

	if [[ -n $PHP_UID ]]; then
		PHP_USER_HOME=$(eval echo "~$PHP_USER_NAME")
		mkdir -p ${PHP_USER_HOME}/.ssh
		echo "${ORO_SSH_PUBLIC_KEY}" > ${PHP_USER_HOME}/.ssh/authorized_keys
		chmod -R 0600 ${PHP_USER_HOME}/.ssh
		chown -R $PHP_USER_NAME ${PHP_USER_HOME}
		usermod -s /bin/bash $PHP_USER_NAME
		# echo "${PHP_USER_HOME}:${PHP_USER_HOME}" | chpasswd
	fi
fi

exec /usr/sbin/sshd -D -e