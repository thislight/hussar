ARCH=`pwd`

cd musl
echo 'ARCH = $ARCH' >> config.mak
echo 'prefix = /usr/local/musl' >> config.mak
echo 'exec_prefix = /usr/local' >> config.mak
echo 'syslibdir = /lib' >> config.mak
cd ..
