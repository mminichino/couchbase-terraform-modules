#!/bin/bash

exec > /var/log/host_init.log 2>&1

FLAG_FILE="/etc/default/.host_init_complete"

if [ -f "$FLAG_FILE" ]; then
  echo "Init script finished, skipping."
  exit 0
fi

apt update -y
apt upgrade -y

apt install -y wget curl gnupg2 software-properties-common jq unzip zip net-tools openjdk-17-jdk python3-pip python3-venv
apt install -y \
    build-essential git \
    libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev \
    libncursesw5-dev xz-utils tk-dev \
    libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev uuid-dev

snap install astral-uv --classic

curl -OLs --output-dir /tmp https://github.com/asdf-vm/asdf/releases/download/v0.19.0/asdf-v0.19.0-linux-amd64.tar.gz
tar xzvf /tmp/asdf-v0.19.0-linux-amd64.tar.gz -C /usr/local/bin
rm /tmp/asdf-v0.19.0-linux-amd64.tar.gz

export HOME=/root

cat << 'EOF' >> $HOME/.bashrc
export PATH=$HOME/.asdf/shims:$PATH
export PATH=$HOME/.local/bin:$PATH
EOF

export PATH=$HOME/.asdf/shims:$HOME/.local/bin:$PATH

asdf plugin add python
asdf install python 3.12.13
asdf reshim
asdf set -u python 3.12.13
uv tool install https://github.com/mminichino/host-prep-lib/releases/download/${host_prep_version}/pyhostprep-${host_prep_version}-py3-none-any.whl
uv tool install ansible-core --with ansible

apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

UID_MIN=1000
while IFS=: read -r username _ uid gid _ home shell; do
    if [[ "$username" == "root" || "$uid" -eq 0 ]]; then
        continue
    fi

    if [[ "$uid" -lt "$UID_MIN" || "$uid" -ge 65534 ]]; then
        continue
    fi

    if id -nG "$username" 2>/dev/null | tr ' ' '\n' | grep -qx "docker"; then
        continue
    fi

    usermod -aG docker "$username"
    echo "Added '$username' to docker group"
done < /etc/passwd

curl -sfL https://get.k3s.io | sh -
chmod +r /etc/rancher/k3s/k3s.yaml
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

touch "$FLAG_FILE"
