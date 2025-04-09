#!/bin/bash
set -ex
[ -f /etc/ssh/hostkeys/ssh_host_rsa_key ] || ssh-keygen -t rsa -f /etc/ssh/hostkeys/ssh_host_rsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ecdsa_key ] || ssh-keygen -t ecdsa -f /etc/ssh/hostkeys/ssh_host_ecdsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -f /etc/ssh/hostkeys/ssh_host_ed25519_key -N ''; \
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_rsa_key/a HostKey /etc/ssh/hostkeys/ssh_host_rsa_key' /etc/ssh/sshd_config
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/a HostKey /etc/ssh/hostkeys/ssh_host_ecdsa_key' /etc/ssh/sshd_config
sed -i '/^#HostKey \/etc\/ssh\/ssh_host_ed25519_key/a HostKey /etc/ssh/hostkeys/ssh_host_ed25519_key' /etc/ssh/sshd_config

exec /usr/sbin/sshd -D