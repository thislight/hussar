LUA_SOURCE_URI="https://www.lua.org/ftp/lua-5.4.1.tar.gz"
LUA_SOURCE_FILENAME="lua-5.4.1.tar.gz"
LUA_SOURCE_DIR="lua-5.4.1"

function check_result(){
    if [ $? != 0 ]; then exit 1; fi;
}

echo "Downloading Lua Source..."
wget $LUA_SOURCE_URI -O $LUA_SOURCE_FILENAME --show-progress -v
check_result
tar -xzf $LUA_SOURCE_FILENAME --verbose
check_result
