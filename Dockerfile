FROM ubuntu:22.04
LABEL org.opencontainers.image.authors="nailuoGG <nailuogg@gmail.com>"

SHELL ["/bin/bash", "-c"]

RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list

# Install gosu
RUN set -eux; \
  apt-get update; \
  apt-get install -y gosu; \
  apt-get autoremove && \
  apt-get clean && \
  gosu nobody true

# Install dependencies and create directories
RUN set -eux; \
    apt-get update && \
    apt-get install curl unzip wget git ca-certificates bash -y --no-install-recommends; \
    useradd -u 666 -U -d /config -s /bin/bash jenkins && \
    usermod -G users jenkins &&  \
    mkdir -p /app /config /defaults /scripts /scripts/.pnpm_home && \
    chown -R jenkins:jenkins /app /config /scripts && \
    apt-get autoremove && \
    apt-get clean

COPY fnm-install.sh /scripts
COPY .npmrc /config/
COPY entrypoint.sh /scripts/entrypoint.sh

ENV PNPM_VERSION=7.33.5 \
    FNM_NODE_DIST_MIRROR='https://mirrors.aliyun.com/nodejs-release/' \
    PNPM_HOME=/scripts/.pnpm_home

ENV PATH=/scripts/.fnm:$PNPM_HOME:$PATH

# Switch to jenkins user for fnm and node installation
USER jenkins

# Install fnm with caching
RUN --mount=type=cache,target=/config/.fnm,id=fnm_cache \
    bash /scripts/fnm-install.sh -d /scripts/.fnm && \
    echo "export PATH=${PATH}" >> /config/.bashrc && \
    echo "eval \"\$(fnm env --use-on-cd)\"" >> /config/.bashrc

# Install pnpm
RUN mkdir -p /scripts/.pnpm_home && \
    wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" PNPM_VERSION="${PNPM_VERSION}" bash - && \
    . /config/.bashrc && \
    pnpm config set store-dir /scripts/pnpm_store

# Install multiple node versions using fnm with caching
RUN --mount=type=cache,target=/config/.fnm,id=fnm_cache \
    eval "$(fnm env)" && \
    fnm install 14 && \
    fnm install 22 && \
    fnm use 22 && \
    echo "test npm config " && \
    pnpm config list && \
    pnpm i -g @tarojs/cli

WORKDIR /app

# Switch back to root user for final setup
USER root

# Ensure proper permissions for pnpm store
RUN mkdir -p /scripts/pnpm_store && \
    chown -R jenkins:jenkins /scripts/pnpm_store

CMD bash /scripts/entrypoint.sh

VOLUME ["/scripts/pnpm_store"]
