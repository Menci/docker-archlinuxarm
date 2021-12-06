ARG PACKAGE_GROUP=base

FROM alpine:3.15 AS bootstrapper
COPY pacman /pacman
RUN \
	apk add arch-install-scripts pacman-makepkg && \
	cat /pacman/repos >> /etc/pacman.conf && \
	cp -r /pacman/keyrings /usr/share/pacman/ && \
	pacman-key --init && \
	pacman-key --populate && \
	mkdir /rootfs && \
	/pacman/pacstrap-docker /rootfs $PACKAGE_GROUP && \
	echo "en_US.UTF-8 UTF-8" > /rootfs/etc/locale.gen && \
	echo "LANG=en_US.UTF-8" > /rootfs/etc/locale.conf && \
	chroot /rootfs locale-gen && \
	rm -rf /rootfs/var/lib/pacman/sync/* /root/pacman

FROM scratch
COPY --from=bootstrapper /rootfs/ /
ENV LANG=en_US.UTF-8
RUN \
	ln -sf /usr/lib/os-release /etc/os-release && \
	pacman-key --init && \
	pacman-key --populate && \
	rm -rf /etc/pacman.d/gnupg/{openpgp-revocs.d/,private-keys-v1.d/,pubring.gpg~,gnupg.S.}*

CMD ["/usr/bin/bash"]
