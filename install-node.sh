#!/usr/bin/env sh

eval "$(fnm env --use-on-cd)"

export FNM_NODE_DIST_MIRROR='https://mirrors.aliyun.com/nodejs-release/'

fnm install 14 && fnm install 20 && fnm install 22

fnm use 22

# 设置环境变量
export PNPM_VERSION=7.33.5

npm config set prefix /config/npm-global

wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.shrc" SHELL="$(which sh)" PNPM_VERSION="${PNPM_VERSION}" sh -

mkdir -p /config/pnpm_store

pnpm config set store-dir /config/pnpm_store
