function check_result(){
    if [ $? != 0 ]; then exit 1; fi;
}

wget https://luarocks.org/releases/luarocks-3.3.1.tar.gz --show-progress -v
check_result
tar zxpf luarocks-3.3.1.tar.gz
check_result
