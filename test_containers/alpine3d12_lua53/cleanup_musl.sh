MUSL_SOURCE_FILENAME="musl-1.2.1.tar.gz"

function check_result(){
    if [ $? != 0 ]; then exit 1; fi;
}

rm -r "musl"
check_result
rm $MUSL_SOURCE_FILENAME
check_result
