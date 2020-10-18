# wget, make and tar are required
MUSL_SOURCE_FILENAME="musl-1.2.1.tar.gz"
MUSL_SOURCE_DIR="musl-1.2.1"
LUA_SOURCE_FILENAME="lua-5.4.1.tar.gz"
LUA_SOURCE_DIR="lua-5.4.1"

function check_result(){
    if [ $? != 0 ]; then exit 1; fi;
}

cd $MUSL_SOURCE_DIR
MUSL_ROOT=`pwd`
cd ..
MUSL_HEADERS="$MUSL_ROOT/include"

cd $LUA_SOURCE_DIR
check_result
MYCLAGS="-isystem $MUSL_HEADERS" make && make install
check_result
cd ..

rm -r $LUA_SOURCE_DIR
check_result
rm $LUA_SOURCE_FILENAME
check_result
rm -r $MUSL_SOURCE_DIR
check_result
rm $MUSL_SOURCE_FILENAME
