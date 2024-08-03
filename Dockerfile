FROM ubuntu:22.04
MAINTAINER nailuoGG <nailuogg@gmail.com>

SHELL ["/bin/bash", "-c"]

RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list
# 安装gosu工具，用于切换到用户来执行命令 # https://github.com/tianon/gosu/blob/master/INSTALL.md
RUN set -eux; \
  apt-get update; \
  apt-get install -y gosu; \
  apt-get autoremove && \
  apt-get clean && \
  gosu nobody true

# 安装必须的依赖，创建需要的目录sd
# /app 是 git 工程，内容等于Jenkins上的工作区，例如 git clone https://github.com/xxxxxx.git app
# /config 主要是镜像内使用的各种配置文件
# /scripts 部分目录需要挂在到volume上
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

# 安装 fnm 管理多个node版本
COPY fnm-install.sh /scripts
# 安装pnpm
#COPY pnpm-install.sh /scripts
# 路径得写完整
COPY .npmrc /config/
# 镜像启动入口
COPY entrypoint.sh /scripts/entrypoint.sh

#设置权限
RUN chown -R jenkins:jenkins /app && \
    chown -R jenkins:jenkins /config && \
    chown -R jenkins:jenkins /scripts

# 切换到Jenkins用户，防止
USER jenkins

# 安装fnm，用来管理node版本
RUN bash /scripts/fnm-install.sh -d /scripts/.fnm

ENV PNPM_VERSION=7.33.5 \
 FNM_NODE_DIST_MIRROR='https://mirrors.aliyun.com/nodejs-release/' \
 PNPM_HOME=/scripts/.pnpm_home

ENV PATH=/scripts/.fnm:$PNPM_HOME:$PATH

RUN echo "export PATH=${PATH}" >> /config/.bashrc
RUN echo "eval \"\$(fnm env --use-on-cd)\"" >> /config/.bashrc

# 切换工作目录
WORKDIR /app

# 安装pnpm
RUN wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" PNPM_VERSION="${PNPM_VERSION}" bash - && \
    mkdir -p /scripts/pnpm_store && \
    pnpm config set store-dir /scripts/pnpm_store

# 使用fnm安装node的多个版本，想要啥版本自己加
RUN eval "$(fnm env)" && \
    fnm install 14 && fnm install 22

# 尝试安装全局工具
RUN cd ~/&& pwd && ls -la &&  \
    eval "$(fnm env)" &&  \
    fnm use 22 && \
    echo "test npm config " && \
    pnpm config list && pnpm i -g @tarojs/cli

# 最后切换回来，在启动容器时需要用root权限更改目录权限，然后再用gosu切换jenkins用户执行bootstrap.sh
USER root

# 用bash跑就不用加执行权限了
CMD bash /scripts/entrypoint.sh

VOLUME ["/scripts/pnpm_store"]
