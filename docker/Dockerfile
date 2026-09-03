FROM ubuntu:22.04

ARG USER_ID=1000
ARG GROUP_ID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    GIT_TERMINAL_PROMPT=0

# Host packages required by Yocto Project (Scarthgap) and kas.
# See: https://docs.yoctoproject.org/brief-yoctoprojectqs/index.html
RUN apt-get update && apt-get install -y --no-install-recommends \
        gawk wget git-core diffstat unzip texinfo gcc g++ build-essential \
        chrpath socat cpio python3 python3-pip python3-pexpect \
        python3-git python3-jinja2 python3-subunit python3-setuptools \
        python3-wheel python3-yaml \
        xz-utils debianutils iputils-ping \
        libegl1-mesa libsdl1.2-dev pylint xterm mesa-common-dev \
        zstd liblz4-tool lz4 file locales libacl1 \
        flex bison libncurses-dev libssl-dev \
        sudo ca-certificates curl rsync \
        vim-tiny less tmux \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && pip3 install --no-cache-dir 'kas==4.7' \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g "${GROUP_ID}" builder \
    && useradd -m -u "${USER_ID}" -g "${GROUP_ID}" -s /bin/bash builder \
    && echo "builder ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/builder \
    && chmod 0440 /etc/sudoers.d/builder \
    && mkdir -p /work \
    && chown builder:builder /work

COPY entrypoint.sh /usr/local/bin/yocto-entrypoint.sh
RUN chmod 755 /usr/local/bin/yocto-entrypoint.sh

USER builder
WORKDIR /work

RUN git config --global user.email "builder@localhost" \
    && git config --global user.name "Yocto Builder" \
    && git config --global --add safe.directory '*'

ENTRYPOINT ["/usr/local/bin/yocto-entrypoint.sh"]
CMD ["bash"]
