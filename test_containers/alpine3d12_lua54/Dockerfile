FROM alpine:3.12

COPY ./enable_community_repo.sh /enable_community_repo.sh
RUN sh /enable_community_repo.sh
RUN apk update
RUN apk add gcc
RUN apk add g++

RUN apk add make
RUN apk add wget tar
RUN apk add readline readline-dev
RUN apk add musl-dev
RUN apk add binutils

COPY ./install_lua54.sh /install_lua54.sh
COPY ./download_lua54.sh /download_lua54.sh
COPY ./download_musl.sh /download_musl.sh
RUN sh /download_lua54.sh
RUN sh /download_musl.sh
RUN sh /install_lua54.sh

RUN apk add unzip

COPY ./download_luarocks.sh /download_luarocks.sh
COPY ./install_luarocks.sh /install_luarocks.sh
RUN sh /download_luarocks.sh
RUN sh /install_luarocks.sh

RUN apk add busybox openssl

RUN luarocks install busted

RUN luarocks install luacov

RUN apk add zlib zlib-dev

CMD sh -c "lua -v && luarocks --version && printf \"busted: \" && busted --version"
