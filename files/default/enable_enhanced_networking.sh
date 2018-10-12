#!/bin/bash
set -e

ena_version=$1
bucket_name=$2

if modinfo ena | grep "^version:\s\+$ena_version" > /dev/null; then
  echo "already installed ena driver $ena_version"
  exit 0;
fi

rm -Rf /root/build_tmp
mkdir -p /root/build_tmp
cd /root/build_tmp

aws s3 cp s3://$bucket_name/amzn-drivers-ena_linux_$ena_version.tar.gz .
tar zxf amzn-drivers-ena_linux_$ena_version.tar.gz

rm -Rf /usr/src/amzn-drivers-$ena_version
mv amzn-drivers-ena_linux_$ena_version /usr/src/amzn-drivers-$ena_version
cd /usr/src/amzn-drivers-$ena_version

(
cat << EOF
PACKAGE_NAME="ena"
PACKAGE_VERSION="$ena_version"
CLEAN="make -C kernel/linux/ena clean"
BUILT_MODULE_NAME[0]="ena"
BUILT_MODULE_LOCATION="kernel/linux/ena"
DEST_MODULE_LOCATION[0]="/updates"
DEST_MODULE_NAME[0]="ena"
AUTOINSTALL="yes"
EOF
) > /usr/src/amzn-drivers-$ena_version/dkms.conf

# $kernelver is a variable set internally by the dkms build process
# append it separately because the bash heredoc would try to interpolate it
echo 'MAKE="make -C kernel/linux/ena/ BUILD_KERNEL=${kernelver}"' >> /usr/src/amzn-drivers-$ena_version/dkms.conf

dkms add -m amzn-drivers -v $ena_version
dkms build -m amzn-drivers -v $ena_version
dkms install -m amzn-drivers -v $ena_version
dkms autoinstall -m amzn-drivers
update-initramfs -c -k all
