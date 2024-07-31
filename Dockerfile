FROM ubuntu:22.04
    MAINTAINER nailuoGG <nailuogg@gmail.com>

SHELL ["/bin/bash", "-c"]

# 安装必须的依赖 curl unzip 更新证书
RUN set -eux; \
    apt-get update && \
    apt-get install curl unzip wget git ca-certificates -y --no-install-recommends; \
    useradd -u 666 -U -d /config -s /bin/false abc && \
    usermod -G users abc &&  \
    mkdir -p \
    /app \
    /config \
    /defaults \
    /scripts  &&\
  echo "**** cleanup ****" && \
  apt-get autoremove && \
  apt-get clean

ADD fnm-install.sh /scripts

RUN chmod +x /scripts/fnm-install.sh && \
    chown abc:abc /scripts/fnm-install.sh

RUN mkdir -p /config/.fnm

# 安装fnm，用来管理node版本
RUN bash /scripts/fnm-install.sh -d /scripts/.fnm

ENV PATH=/scripts/.fnm:$PATH

# 处理fnm的环境变量
RUN echo "eval \"\$(fnm env --use-on-cd)\"" >> /config/.bashrc
COPY .npmrc /config/

# 切换工作目录
WORKDIR /app

ENV PNPM_HOME=/scripts/.pnpm_home
ENV PATH=$PNPM_HOME:$PATH

# 使用fnm安装node的多个版本，想要啥版本自己加
ADD install-node.sh /scripts
RUN bash /scripts/install-node.sh

COPY bootstrap.sh /

RUN chmod +x /bootstrap.sh

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD /entrypoint.sh && bash  /app/run.sh

VOLUME ["/scripts/pnpm_store" , "/scripts/npm-global"]
