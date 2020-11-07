FROM debian:bullseye-slim

RUN apt update
RUN apt upgrade -y
RUN apt install -y gcc
RUN apt install -y g++
RUN apt install -y unzip openssl busybox
RUN apt install -y wget tar make
RUN apt install -y libreadline-dev

COPY ./install_lua53.sh /install_lua53.sh
COPY ./download_lua53.sh /download_lua53.sh
RUN bash /download_lua53.sh
RUN bash /install_lua53.sh

COPY ./download_luarocks.sh /download_luarocks.sh
COPY ./install_luarocks.sh /install_luarocks.sh
RUN bash /download_luarocks.sh
RUN bash /install_luarocks.sh
RUN luarocks install busted
RUN luarocks install luacov

CMD sh -c "lua -v && luarocks --version && printf \"busted: \" && busted --version"
