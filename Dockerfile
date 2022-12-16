FROM alpine:20221110 AS bootstrapper
ARG TARGETARCH
ARG PACKAGE_GROUP=base
COPY files /files
RUN \
	apk add arch-install-scripts pacman-makepkg curl && \
	cat /files/repos-$TARGETARCH >> /etc/pacman.conf && \
	mkdir -p /etc/pacman.d && \
	cp /files/mirrorlist-$TARGETARCH /etc/pacman.d/mirrorlist && \
	if [[ "$TARGETARCH" == "arm64" ]]; then \
			curl -L https://github.com/archlinuxarm/archlinuxarm-keyring/archive/refs/heads/master.zip | unzip -d /tmp/archlinuxarm-keyring - && \
			mkdir /usr/share/pacman/keyrings && \
			mv /tmp/archlinuxarm-keyring/*/archlinuxarm* /usr/share/pacman/keyrings/; \
	else \
			apk add zstd && \
			mkdir /tmp/archlinux-keyring && \
			curl -L https://archlinux.org/packages/core/any/archlinux-keyring/download | unzstd | tar -C /tmp/archlinux-keyring -xv && \
			mv /tmp/archlinux-keyring/usr/share/pacman/keyrings /usr/share/pacman/; \
	fi && \
	pacman-key --init && \
	pacman-key --populate && \
	mkdir /rootfs && \
	/files/pacstrap-docker /rootfs $PACKAGE_GROUP && \
	cp /etc/pacman.d/mirrorlist /rootfs/etc/pacman.d/mirrorlist && \
	echo "en_US.UTF-8 UTF-8" > /rootfs/etc/locale.gen && \
	echo "LANG=en_US.UTF-8" > /rootfs/etc/locale.conf && \
	chroot /rootfs locale-gen && \
	rm -rf /rootfs/var/lib/pacman/sync/* /rootfs/files

FROM scratch
COPY --from=bootstrapper /rootfs/ /
ENV LANG=en_US.UTF-8
RUN \
	ln -sf /usr/lib/os-release /etc/os-release && \
	pacman-key --init && \
	pacman-key --populate && \
	rm -rf /etc/pacman.d/gnupg/{openpgp-revocs.d/,private-keys-v1.d/,pubring.gpg~,gnupg.S.}*

CMD ["/usr/bin/bash"]
