#!/bin/bash
set -ex
[ -f /etc/ssh/hostkeys/ssh_host_rsa_key ] || ssh-keygen -t rsa -f /etc/ssh/hostkeys/ssh_host_rsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ecdsa_key ] || ssh-keygen -t ecdsa -f /etc/ssh/hostkeys/ssh_host_ecdsa_key -N ''; \
[ -f /etc/ssh/hostkeys/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -f /etc/ssh/hostkeys/ssh_host_ed25519_key -N ''; \
sed -i 's|^HostKey .*rsa.*|HostKey /etc/ssh/hostkeys/ssh_host_rsa_key|' /etc/ssh/sshd_config; \
sed -i 's|^HostKey .*ecdsa.*|HostKey /etc/ssh/hostkeys/ssh_host_ecdsa_key|' /etc/ssh/sshd_config; \
sed -i 's|^HostKey .*ed25519.*|HostKey /etc/ssh/hostkeys/ssh_host_ed25519_key|' /etc/ssh/sshd_config; \

exec /usr/sbin/sshd