FROM debian:bullseye

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 \
    python3-pip \
    debootstrap \
    xorriso \
    isolinux \
    syslinux-common \
    squashfs-tools \
    sudo \
    curl \
    ca-certificates \
    gnupg2 \
    apt-transport-https \
    wget \
    coreutils \
    util-linux \
    x11-xserver-utils \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install pyyaml

RUN mkdir -p /etc/systemd/system \
    && mkdir -p /var/lib/dpkg \
    && mkdir -p /var/lib/apt/lists

WORKDIR /app

COPY src/ /app/src/
COPY kioskbuilder.py /app/

ENTRYPOINT ["python3", "/app/kioskbuilder.py", "-c", "/config.yml", "-o", "/output"]
