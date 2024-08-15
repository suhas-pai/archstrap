FROM alpine:latest AS builder

WORKDIR /tmp
ADD . .

RUN apk --update add bash curl coreutils gnupg zstd
RUN bash ./get-archlinux-bootstrap.sh

FROM scratch
ENV XSTOW_VERSION=1.1.1

COPY --from=builder /tmp/bootstrap/root.x86_64 /

RUN locale-gen
RUN pacman-key --init
RUN pacman-key --populate archlinux
RUN echo "Server = https://archive.archlinux.org/repos/2024/08/03/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
RUN pacman -Sy --noconfirm archlinux-keyring
RUN pacman -S --noconfirm pacman pacman-mirrorlist
RUN pacman -Syu --noconfirm
RUN sed -i "s/ check / !check /g" /etc/makepkg.conf

RUN for f in $(find / -perm 000 2>/dev/null); do chmod 755 "$f"; done
RUN pacman --needed --noconfirm -S bison diffutils docbook-xsl flex gettext inetutils libtool libxslt m4 make patch perl python texinfo w3m which xmlto vim zsh nasm xorriso rsync

RUN curl -Lo "xstow-${XSTOW_VERSION}.tar.gz" https://github.com/majorkingleo/xstow/releases/download/${XSTOW_VERSION}/xstow-${XSTOW_VERSION}.tar.gz
RUN mkdir -p xstow_buildenv
RUN gunzip < /xstow-${XSTOW_VERSION}.tar.gz | tar -xf -
RUN ls /xstow-${XSTOW_VERSION}
RUN pacman -S --noconfirm base-devel
RUN cd /xstow-${XSTOW_VERSION} && ./configure LDFLAGS='-static' --enable-static --enable-merge-info --without-curses && make -j2
RUN mv /xstow-${XSTOW_VERSION}/src/merge-info /
RUN rm -rf /xstow_buildenv
RUN rm /xstow-${XSTOW_VERSION}.tar.gz

RUN mkdir -p /tmp/iso_root
RUN rsync -av --exclude='/tmp' --exclude='/sys' --exclude='/proc' --exclude='/boot' --exclude='/EFI' --exclude='/dev' / /tmp/iso_root
RUN cd /tmp/iso_root && tar -czf /tmp/template-x86_64.tar.gz .

CMD ["/bin/bash"]
