
ARCH=`uname -m`
CDIR=`pwd`
if [ $CDIR = "/" ]; then CDIR=""; fi

echo "Target Platform: $ARCH"

luarocks install busted CFLAGS="-isystem /usr/include/linux -isystem $CDIR/musl/include -isystem $CDIR/musl/arch/$ARCH"
