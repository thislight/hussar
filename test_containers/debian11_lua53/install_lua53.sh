# wget, make and tar are required
LUA_SOURCE_FILENAME="lua-5.3.6.tar.gz"
LUA_SOURCE_DIR="lua-5.3.6"

function check_result(){
    if [ $? != 0 ]; then exit 1; fi;
}

cd $LUA_SOURCE_DIR
check_result
make linux && make install
check_result
cd ..

rm -r $LUA_SOURCE_DIR
check_result
rm $LUA_SOURCE_FILENAME
check_result
