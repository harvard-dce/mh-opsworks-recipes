#!/bin/bash
set -e
dkms_version=$1
bucket_name=$2

if modinfo ixgbevf | grep $dkms_version > /dev/null; then
  echo "already installed ixgbevf $dkms_version"
  exit 0;
fi

rm -Rf /root/build_tmp/
mkdir -p /root/build_tmp
cd /root/build_tmp

aws s3 cp s3://$bucket_name/ixgbevf-$dkms_version.tar.gz .
tar zxf ixgbevf-$dkms_version.tar.gz
mv ixgbevf-$dkms_version /usr/src/
cd /usr/src/ixgbevf-$dkms_version

echo 'PACKAGE_NAME="ixgbevf"' > /usr/src/"ixgbevf-${dkms_version}"/dkms.conf
echo "PACKAGE_VERSION=\"${dkms_version}\"" >> /usr/src/"ixgbevf-${dkms_version}"/dkms.conf
echo '
CLEAN="cd src/; make clean"
MAKE="cd src/; make BUILD_KERNEL=${kernelver}"
BUILT_MODULE_LOCATION[0]="src/"
BUILT_MODULE_NAME[0]="ixgbevf"
DEST_MODULE_LOCATION[0]="/updates"
DEST_MODULE_NAME[0]="ixgbevf"
AUTOINSTALL="yes"
' >> /usr/src/"ixgbevf-${dkms_version}"/dkms.conf &&

aws s3 cp s3://$bucket_name/patch-ubuntu_14.04.1-ixgbevf-$dkms_version-kcompat.h.patch .
cd src
patch -p5 < ../patch-ubuntu_14.04.1-ixgbevf-$dkms_version-kcompat.h.patch
dkms add -m ixgbevf -v $dkms_version
dkms build -m ixgbevf -v $dkms_version
dkms install -m ixgbevf -v $dkms_version
update-initramfs -c -k all
