# Arch Linux Docker Image (Multiarch)

[![Build and Push](https://github.com/Menci/docker-archlinuxarm/actions/workflows/build.yaml/badge.svg)](https://github.com/Menci/docker-archlinuxarm/actions/workflows/build.yaml)

This is the Docker image for Arch Linux ARM but for compatibility AMD64 build is also included. All images are built on GitHub Actions automatically.

Just just like the official Arch Linux AMD64 image, it has two tags:

* `base` (default): installed only the package group `base`.
* `base-devel`: installed the package group `base-devel`.

And, the pamcan lsign-key is also removed for [security reasons](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/bc4d9f8ec5bdcbedefc96a2a1beaf33f01c07812/README.md#principles).

# Under the Hood

The Dockerfile uses a Alpine Linux container to install `pacman` and bootstrap the Arch Linux ARM rootfs. Since `pacstrap` uses `mount`, it doesn't run in an unprivileged Docker container. I found the tool [`pacstrap-docker`](https://github.com/lopsided98/archlinux-docker/blob/d5a80b90aea37eee43bcc7efeaea69880a4aada7/pacstrap-docker) ([LICENSE](https://github.com/lopsided98/archlinux-docker/blob/d5a80b90aea37eee43bcc7efeaea69880a4aada7/LICENSE)) as a replacement.

After bootstrapping, the rootfs will be copied to a new container from `scratch` (aka. an empty file system), which will be commited as the result image.
