#! /bin/sh
NAME=clefISN
DEBIAN=wheezy
ARCH=i386
KERNEL="linux-image-486" # let the system pick the most recent one
USER=isn
# Testing user ID
uid=$(/usr/bin/id -u)
if [ $uid != "0" ] ; then
  echo "Please make sure to become root before running me" 2>&1 ;
  exit 1
fi


set -ex
# To debug the script, it's handy to change to false, and put the fi to avoid what worked for you so far
if true ; then
MIRROR="http://debian.mines.inpl-nancy.fr/debian/"

INCLUDEPKG="--include=xorg,xfce4,desktop-base,arandr,wicd"

echo "XXX download the elements"
if [ -e debootstrap-${ARCH}.cache.tgz ] ; then
  echo "Updating the archive that already exists";
  debootstrap $INCLUDEPKG --arch $ARCH --unpack-tarball=`pwd`/debootstrap-${ARCH}.cache.tgz --make-tarball=debootstrap-${ARCH}.cache.tgz $DEBIAN $NAME $MIRROR
else
  debootstrap $INCLUDEPKG --arch $ARCH                                                      --make-tarball=debootstrap-${ARCH}.cache.tgz $DEBIAN $NAME $MIRROR
fi

echo "XXX building the chroot"
debootstrap $INCLUDEPKG --unpack-tarball=`pwd`/debootstrap-${ARCH}.cache.tgz --arch ${ARCH} $DEBIAN $NAME $MIRROR

# root password is isnlive
sed -i -e '1,$s/root:\*:/root:FBa41ZgngtSCI:/' $NAME/etc/shadow


echo "XXX add backports to the apt sources"
# initramfs
cat > $NAME/etc/apt/sources.list <<EOF
deb http://ftp.fr.debian.org/debian/ experimental main contrib non-free

deb http://ftp.fr.debian.org/debian/ $DEBIAN main contrib non-free
deb-src http://ftp.fr.debian.org/debian/ $DEBIAN main contrib non-free

deb http://ftp.fr.debian.org/debian/ stable main contrib non-free

deb http://boisson.homeip.net/debian $DEBIAN divers
deb-src http://boisson.homeip.net/sources/ ./

deb http://security.debian.org/ $DEBIAN/updates main
deb-src http://security.debian.org/ $DEBIAN/updates main

deb http://backports.debian.org/debian-backports ${DEBIAN}-backports main

EOF

echo "XXX install our initramfs"
chroot $NAME sh -c "apt-get update; apt-get  install  --yes  initramfs-tools"
zcat initramfs-isn.tgz | (cd $NAME ; tar x)

echo "XXX install a kernel"
chroot $NAME sh -c "apt-get  install  --yes  $KERNEL"
chroot $NAME sh -c "apt-get  install  --yes mingetty"
fi


chroot $NAME sh -c "apt-get  install  --yes sudo rsync"
chroot $NAME sh -c "apt-get  install  --yes  locales"
cp /etc/locale.gen $NAME/etc
chroot $NAME locale-gen
cat <<EOF > $NAME/etc/default/locale
LANGUAGE="fr_FR:fr:en_GB:en"
LANG="fr_FR.UTF-8"
EOF
if [ ! -z "$(ls live-isn*deb)" ] ; then
    cp $(ls live-isn*deb) $NAME/tmp
    chroot $NAME sh -c "dpkg -i tmp/*.deb"
    rm $NAME/tmp/*.deb
chroot $NAME sh -c "apt-get clean"

# Setup the system skeleton

# Create a user
chroot $NAME sh -c "adduser --disabled-password --gecos \"Utilisateur ISN\" --quiet $USER"
fi    
sed -i -e '1,$s/^'$USER':x:/'$USER'::/' $NAME/etc/passwd
sed -i -e '1,$s/^'$USER':.:/'$USER'::/' $NAME/etc/shadow

sed -i -e '1,$s|^1:2345:respawn:/sbin/getty 38400 tty1|1:2345:respawn:/sbin/mingetty --noclear --autologin '$USER' tty1|' $NAME/etc/inittab




mksquashfs $NAME basesystem.sqh -e $NAME/proc -e $NAME/var/run -e $NAME/run -e $NAME/dev

