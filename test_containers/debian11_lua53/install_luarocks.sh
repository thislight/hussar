function check_result(){
    if [ $? != 0 ]; then exit 1; fi;
}

cd luarocks-3.3.1
check_result
./configure --with-lua-include=/usr/include/
check_result
make
check_result
make install
check_result
cd ..
check_result

rm -r luarocks-3.3.1
check_result
rm luarocks-3.3.1.tar.gz
check_result
