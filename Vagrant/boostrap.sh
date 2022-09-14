#!/bin/bash

echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
LISTS HOSTS
EOF

echo "[TASK 2] Install docker"
yum install -y -q yum-utils device-mapper-persistent-date lvm2 > /dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > 2>&1
yum install -y -q docker-ce > /dev/null 2>&1

echo "[TASK 3] Actif and run a service docker"
systemctl enable docker > /dev/null 2>&1
systemctl start docker

echo "[TASK 4] Disable SELinux"
setenforce 0
sed -i --follow-symlinks 's/^SELINUX-enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

echo "[TASK 5] Disable and stop a service firewalld"
systemctl disable firewalld > /dev/null 2>&1
systemctl stop firewalld

echo "[TASK 6] Other parameter sysctl"
cat >>/etc/sysctl/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system > /dev/null 2>&1

echo "[TASK 7] Disable and stop a service swap"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK 8] Add repo kubernetes"
cat >>/etc/yum.repo.d/kubernetes.repo<<EOF
ALL REPO KUBERNETES
EOF

echo "[TASK 9] Install kubernetes (kubeadm, kubelet and kubectl)"
yum install -y -q kubeadm kubelet kubectl > /dev/null 2>&1

echo "[TASK 10] Active and run a service kubelet"
systemctl enable kubelet > /dev/null 2>&1
systemctl start kubelet > /dev/null 2>&1

echo "[TASK 11] Active authentification ssh"
sed -i 's/^PasswordAuthentification no/PasswordAuthentification yes/' /etc/sshd_config
systemctl reload sshd

echo "[TASK 12] Password root"
echo "root" | passwd --stdin root > /dev/null 2>&1
