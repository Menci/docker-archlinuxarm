FROM debian:sid AS bootstrapper
ARG TARGETARCH
ARG PACKAGE_GROUP=base
COPY files /files
RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends arch-install-scripts pacman-package-manager makepkg curl ca-certificates xz-utils zstd && \
	cat /files/repos-$TARGETARCH >> /etc/pacman.conf && \
	sed -i "s/^CheckSpace/#CheckSpace/" /etc/pacman.conf && \
	mkdir -p /etc/pacman.d && \
	cp /files/mirrorlist-$TARGETARCH /etc/pacman.d/mirrorlist && \
	BOOTSTRAP_EXTRA_PACKAGES="" && \
	if case "$TARGETARCH" in arm*) true;; *) false;; esac; then \
			EXTRA_KEYRING_FILES=" \
				archlinuxarm-revoked \
				archlinuxarm-trusted \
				archlinuxarm.gpg \
			" && \
			EXTRA_KEYRING_URL="https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/master/core/archlinuxarm-keyring/" && \
			for EXTRA_KEYRING_FILE in $EXTRA_KEYRING_FILES; do \
				curl "$EXTRA_KEYRING_URL$EXTRA_KEYRING_FILE" -o /usr/share/keyrings/$EXTRA_KEYRING_FILE -L; \
			done && \
			BOOTSTRAP_EXTRA_PACKAGES="archlinuxarm-keyring"; \
	else \
			mkdir /tmp/archlinux-keyring && \
			curl -L https://archlinux.org/packages/core/any/archlinux-keyring/download | unzstd | tar -C /tmp/archlinux-keyring -xv && \
			mv /tmp/archlinux-keyring/usr/share/pacman/keyrings/* /usr/share/keyrings/; \
	fi && \
	pacman-key --init && \
	pacman-key --populate && \
	mkdir /rootfs && \
	/files/pacstrap-docker /rootfs $PACKAGE_GROUP $BOOTSTRAP_EXTRA_PACKAGES && \
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
