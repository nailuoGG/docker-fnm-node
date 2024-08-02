FROM ubuntu:22.04
    MAINTAINER nailuoGG <nailuogg@gmail.com>


SHELL ["/bin/bash", "-c"]

# 给UBUNTU换源，不然国内打镜像要累死
RUN     sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list

# 安装gosu工具，用于切换到用户来执行命令 # https://github.com/tianon/gosu/blob/master/INSTALL.md
RUN set -eux; \
  apt-get update; \
  apt-get install -y gosu; \
  rm -rf /var/lib/apt/lists/*; \
  # verify that the binary works
  gosu nobody true

# 安装必须的依赖，创建需要的目录
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


#设置权限
RUN chown -R jenkins:jenkins /app && \
    chown -R jenkins:jenkins /config && \
    chown -R jenkins:jenkins /scripts

USER jenkins

COPY fnm-install.sh /scripts

# 安装fnm，用来管理node版本
RUN bash /scripts/fnm-install.sh -d /scripts/.fnm

ENV PNPM_VERSION=7.33.5 \
 FNM_NODE_DIST_MIRROR='https://mirrors.aliyun.com/nodejs-release/' \
 PNPM_HOME=/scripts/.pnpm_home

ENV PATH=/scripts/.fnm:$PNPM_HOME:$PATH

RUN echo "export PATH=${PATH}" >> ~/.bashrc
RUN echo "eval \"\$(fnm env --use-on-cd)\"" >> ~/.bashrc

COPY .npmrc ~/.npmrc

# 切换工作目录
WORKDIR /app


# 安装pnpm
RUN wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.shrc" SHELL="$(which sh)" PNPM_VERSION="${PNPM_VERSION}" sh - && \
    mkdir -p /scripts/pnpm_store && \
    pnpm config set store-dir /scripts/pnpm_store

# 使用fnm安装node的多个版本，想要啥版本自己加
RUN eval "$(fnm env)" && \
    fnm install 14 && fnm install 22 && \
    fnm use 14

# 该工具安装耗时2~5分钟以上，这里需要将小程序上传工具打包到镜像里，避免每次运行Jenkins打包都重复安装
# RUN npm install -g @yt/miniprogram-ci

# 镜像启动入口
COPY entrypoint.sh /scripts/entrypoint.sh

# 最后切换回来，在启动容器时需要用root权限更改目录权限，然后再用gosu切换jenkins用户执行bootstrap.sh
USER root

# 用bash跑就不用加执行权限了
CMD bash /scripts/entrypoint.sh

VOLUME ["/scripts/pnpm_store"]
