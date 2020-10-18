FROM alpine:3.12

COPY ./enable_community_repo.sh /enable_community_repo.sh
RUN sh /enable_community_repo.sh
RUN apk update
RUN apk add clang
RUN apk add lua5.3 lua5.3-dev lua5.3-libs
RUN apk add luarocks
RUN apk add lua-busted
RUN ln /usr/bin/lua5.3 /usr/bin/lua

CMD sh -c "lua -v && luarocks --version && printf \"busted: \" && busted --version"
