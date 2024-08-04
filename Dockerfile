FROM ubuntu:22.04
LABEL org.opencontainers.image.authors="nailuoGG <nailuogg@gmail.com>"

# 设置默认shell
#
SHELL ["/bin/bash", "-c"]

RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list

# Install gosu tool to switch to user for executing commands
# https://github.com/tianon/gosu/blob/master/INSTALL.md
RUN set -eux; \
  apt-get update; \
  apt-get install -y gosu; \
  apt-get autoremove && \
  apt-get clean && \
  gosu nobody true

# Install necessary dependencies and create needed directories
# /app is the git project, contents equal to Jenkins workspace, e.g. git clone https://github.com/xxxxxx.git app
# /config main configuration files used inside the image
# /scripts part of directories need to be mounted as a volume
RUN set -eux; \
    apt-get update && \
    apt-get install curl unzip wget git ca-certificates bash -y --no-install-recommends; \
    useradd -u 666 -U -d /config -s /bin/bash jenkins && \
    usermod -G users jenkins &&  \
    mkdir -p \
    /app \
    /config \
    /defaults \
    /scripts && \
    apt-get autoremove && \
    apt-get clean

# Install fnm to manage multiple node versions
COPY fnm-install.sh /scripts

# Install pnpm
# COPY pnpm-install.sh /scripts

# Copy .npmrc file to /config directory
COPY .npmrc /config/

# Set image startup entry point
COPY entrypoint.sh /scripts/entrypoint.sh

# Set permissions
RUN chown -R jenkins:jenkins /app && \
    chown -R jenkins:jenkins /config && \
    chown -R jenkins:jenkins /scripts

# thanks to BuildKit
RUN --mount=type=cache,target=/config/.fnm,id=npm_cache sharing=locked  \
    chown -R jenkins:jenkins /config/.fnm && \
    echo "Permission granted to jenkins user.1"

# Switch to Jenkins user to prevent issues
USER jenkins

# Install fnm and manage node versions
RUN --mount=type=cache,target=/config/.fnm,id=npm_cache sharing=locked bash /scripts/fnm-install.sh -d /scripts/.fnm

ENV PNPM_VERSION=7.33.5 \
 FNM_NODE_DIST_MIRROR='https://mirrors.aliyun.com/nodejs-release/' \
 PNPM_HOME=/scripts/.pnpm_home

ENV PATH=/scripts/.fnm:$PNPM_HOME:$PATH

RUN echo "export PATH=${PATH}" >> /config/.bashrc
RUN echo "eval \"\$(fnm env --use-on-cd)\"" >> /config/.bashrc

# Set working directory to /app
WORKDIR /app

# Install pnpm
RUN wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" PNPM_VERSION="${PNPM_VERSION}" bash - && \
    mkdir -p /scripts/pnpm_store && \
    pnpm config set store-dir /scripts/pnpm_store


# Install multiple node versions using fnm
RUN eval "$(fnm env)" && \
    fnm install 14 && fnm install 22

RUN cd ~/&& pwd && ls -la

# Try to install global tools
RUN eval "$(fnm env)" &&  \
    fnm use 22 && \
    echo "test npm config " && \
    pnpm config list && pnpm i -g @tarojs/cli

# Switch back to root user for permission changes
USER root

# Run entry point script using bash (no need for execution permissions)
CMD bash /scripts/entrypoint.sh

VOLUME ["/scripts/pnpm_store"]
