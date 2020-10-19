FROM debian:bullseye-slim

RUN apt update
RUN apt upgrade -y
RUN apt install -y build-essential gcc
RUN apt install -y unzip openssl busybox
RUN apt install -y lua5.3 liblua5.3-0 liblua5.3-dev

COPY ./download_luarocks.sh /download_luarocks.sh
COPY ./install_luarocks.sh /install_luarocks.sh
RUN apt install -y wget tar make
RUN bash /download_luarocks.sh
RUN bash /install_luarocks.sh
RUN apt install -y lua-busted

CMD sh -c "lua -v && luarocks --version && printf \"busted: \" && busted --version"
