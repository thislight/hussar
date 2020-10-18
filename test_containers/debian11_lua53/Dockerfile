FROM debian:bullseye-slim

RUN apt update
RUN apt upgrade -y
RUN apt install -y build-essential gcc
RUN apt install -y unzip openssl busybox
RUN apt install -y lua5.3 luarocks liblua5.3-0 liblua5.3-dev
RUN apt install -y lua-busted

CMD sh -c "lua -v && luarocks --version && printf \"busted: \" && busted --version"
