#!/bin/bash

exec > /var/log/host_init.log 2>&1

FLAG_FILE="/etc/default/.host_init_complete"
mkdir -p "$(dirname "$FLAG_FILE")"

if [ -f "$FLAG_FILE" ]; then
  echo "Init script finished, skipping."
  exit 0
fi

dnf update -y

dnf install -y wget curl gnupg2 jq unzip zip net-tools java-17-openjdk-devel python3-pip
dnf install -y \
    gcc gcc-c++ make git \
    openssl-devel zlib-devel bzip2-devel \
    readline-devel sqlite-devel \
    ncurses-devel xz-devel tk-devel \
    libxml2-devel xmlsec1-devel \
    libffi-devel libuuid-devel

curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

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

bundlemgr -b GenDataDisk

touch "$FLAG_FILE"
