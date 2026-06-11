#!/bin/bash

exec > /var/log/host_init.log 2>&1

FLAG_FILE="/etc/default/.host_init_complete"

if [ -f "$FLAG_FILE" ]; then
  echo "Init script finished, skipping."
  exit 0
fi

apt update -y
apt upgrade -y

apt install -y wget curl gnupg2 software-properties-common jq unzip zip net-tools
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
export PATH=/opt/couchbase/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
EOF

export PATH=$HOME/.asdf/shims:$HOME/.local/bin:$PATH

asdf plugin add python
asdf install python 3.12.13
asdf reshim
asdf set -u python 3.12.13
uv tool install https://github.com/mminichino/host-prep-lib/releases/download/${host_prep_version}/pyhostprep-${host_prep_version}-py3-none-any.whl
uv tool install ansible-core --with ansible

bundlemgr -b CBS -V ${version}

touch "$FLAG_FILE"
