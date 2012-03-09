#! /bin/sh

# Testing user ID
uid=$(/usr/bin/id -u)
if [ $uid != "0" ] ; then
  echo "Please make sure to become root before running me" 2>&1 ;
  exit 1
fi


set -ex

MIRROR="http://debian.mines.inpl-nancy.fr/debian/"

INCLUDEPKG="--include=xorg,lxde,gdm,network-manager-gnome,desktop-base"

echo "XXX download the elements"
if [ -e debootstrap.cache.tgz ] ; then
  echo "archive already existing";
else
  debootstrap $INCLUDEPKG --make-tarball=debootstrap.cache.tgz --arch=i386 stable chroot $MIRROR
fi

echo "XXX building the chroot"
debootstrap $INCLUDEPKG --unpack-tarball=`pwd`/debootstrap.cache.tgz --arch=i386 stable chroot $MIRROR

echo "XXX add backports to the apt sources"
sh -c "echo 'deb http://backports.debian.org/debian-backports squeeze-backports main' >> chroot/etc/apt/sources.list"

echo "XXX install a kernel"
chroot chroot sh -c "apt-get update; apt-get -t squeeze-backports install --yes linux-image-486"


#  attempt to clear root password in order to log in gdm. 
#  But no way ! Users are propably created in init script, aren't they ?
#echo "XXX  clear root password in /etc/shadow"
#sed "s/root:\*:/root::/" chroot/etc/shadow
#

echo "XXX Generate the initrd"
./make-initrd.sh

echo "XXX Compressing the squash filesystem"
mksquashfs chroot basesystem.sqh

