FROM alpine:3.12

COPY ./enable_community_repo.sh /enable_community_repo.sh
RUN sh /enable_community_repo.sh
RUN apk update
RUN apk add gcc
RUN apk add lua5.3 lua5.3-dev lua5.3-libs
RUN ln /usr/bin/lua5.3 /usr/bin/lua

RUN apk add unzip
RUN apk add wget tar
RUN apk add openssl
RUN apk add make
RUN apk add linux-headers

COPY ./download_luarocks.sh /download_luarocks.sh
COPY ./install_luarocks.sh /install_luarocks.sh
COPY ./download_musl.sh /download_musl.sh
COPY ./cleanup_musl.sh /cleanup_musl.sh
COPY ./gen_musl_config.sh /gen_musl_config.sh
RUN sh /download_luarocks.sh
RUN sh /install_luarocks.sh
RUN sh /download_musl.sh

COPY ./install_busted.sh /install_busted.sh
RUN sh /install_busted.sh

RUN sh /cleanup_musl.sh

CMD sh -c "lua -v && luarocks --version && printf \"busted: \" && busted --version"
