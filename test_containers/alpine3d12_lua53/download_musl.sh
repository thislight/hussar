MUSL_SOURCE_URI="https://musl.libc.org/releases/musl-1.2.1.tar.gz"
MUSL_SOURCE_FILENAME="musl-1.2.1.tar.gz"
MUSL_SOURCE_DIR="musl-1.2.1"

function check_result(){
    if [ $? != 0 ]; then exit 1; fi;
}

echo "Download Musl Source..."
wget $MUSL_SOURCE_URI -O $MUSL_SOURCE_FILENAME --show-progress -v
check_result
tar -xzf $MUSL_SOURCE_FILENAME --verbose
check_result
mv $MUSL_SOURCE_DIR musl
check_result
source /gen_musl_config.sh
cd musl
check_result
make
check_result
cd ..
check_result
