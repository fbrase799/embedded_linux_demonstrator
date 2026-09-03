# Generate a self-contained A/B update bundle (.eldupdate) from the rootfs tarball.
#
# Bundle contents:
#   manifest.json   version, machine, sha256 of the rootfs archive
#   rootfs.tar.gz   Yocto root filesystem

IMAGE_TYPES += "eldupdate"
IMAGE_TYPEDEP:eldupdate = "tar.gz"

IMAGE_CMD:eldupdate() {
    bun_dir="${WORKDIR}/eldupdate"
    rm -rf "$bun_dir"
    mkdir -p "$bun_dir"

    rootfs_tar="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.tar.gz"
    if [ ! -f "$rootfs_tar" ]; then
        rootfs_tar="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.tar.gz"
    fi

    cp "$rootfs_tar" "$bun_dir/rootfs.tar.gz"
    sha256=$(sha256sum "$bun_dir/rootfs.tar.gz" | awk '{print $1}')

    printf '{\n  "name": "embedded-linux-demo",\n  "version": "%s",\n  "compatible": "%s",\n  "rootfs_sha256": "%s",\n  "format": 1\n}\n' \
        "${DISTRO_VERSION}" "${MACHINE}" "$sha256" > "$bun_dir/manifest.json"

    tar -czf "${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.eldupdate" \
        -C "$bun_dir" manifest.json rootfs.tar.gz

    ln -sf "${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.eldupdate" \
        "${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.eldupdate"
}
