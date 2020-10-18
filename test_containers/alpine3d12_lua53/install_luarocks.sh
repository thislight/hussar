function check_result(){
    if [ $? != 0 ]; then exit 1; fi;
}

cd luarocks-3.3.1
check_result
./configure --with-lua-include=/usr/include/lua5.3
check_result
make
check_result
make install
check_result
cd ..
check_result
