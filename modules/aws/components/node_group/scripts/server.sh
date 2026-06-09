#!/bin/bash

exec > /var/log/host_init.log 2>&1

FLAG_FILE="/etc/default/.host_init_complete"

if [ -f "$FLAG_FILE" ]; then
  echo "Init script finished, skipping."
  exit 0
fi

apt update -y
apt upgrade -y

apt install -y wget curl gnupg2 software-properties-common jq unzip zip

if [ -b /dev/xvdb ]; then
    DATA_DISK=/dev/xvdb
    PARTITION=/dev/xvdb1
elif [ -b /dev/sdb ]; then
    DATA_DISK=/dev/sdb
    PARTITION=/dev/sdb1
else
    ROOT_DISK=$(lsblk -no pkname "$(findmnt -n -o SOURCE /)")
    DATA_DISK=$(lsblk -dpno NAME,TYPE | awk '$2=="disk" && $1!="/dev/'"$ROOT_DISK"'" {print $1; exit}')
    PARTITION="$${DATA_DISK}p1"
fi

if [ -z "$DATA_DISK" ] || [ -z "$PARTITION" ]; then
  echo "No data disk found"
  exit 1
fi

parted "$DATA_DISK" --script mklabel gpt
parted "$DATA_DISK" --script mkpart primary ext4 0% 100%

partprobe "$DATA_DISK"
udevadm settle

mkfs.ext4 -F "$PARTITION"

mkdir -p /data

mount "$PARTITION" /data

UUID=$(blkid -s UUID -o value "$PARTITION")
echo "UUID=$UUID /data ext4 defaults,nofail 0 2" >> /etc/fstab

mkdir /tmp/couchbase
cd /tmp/couchbase || exit

echo "Installing Couchbase Enterprise"

echo "Downloading installation file"
curl -sLO https://packages.couchbase.com/releases/${version}/couchbase-server-enterprise_${version}-linux_amd64.deb

apt install ./couchbase-server-enterprise_${version}-linux_amd64.deb

cd /
rm -rf /tmp/couchbase

usermod -a -G couchbase ubuntu
cat <<EOF >> /home/ubuntu/.bashrc
export PATH=/opt/couchbase/bin:$PATH
EOF

sudo chown -R couchbase:couchbase /data

touch "$FLAG_FILE"
