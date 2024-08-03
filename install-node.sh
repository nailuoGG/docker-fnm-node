#!/usr/bin/env sh

eval "$(fnm env --use-on-cd)"

# export FNM_NODE_DIST_MIRROR='https://mirrors.aliyun.com/nodejs-release/'
export FNM_NODE_DIST_MIRROR='https://registry.npmmirror.com/-/binary/node/'

fnm install 14 && fnm install 22

fnm use 14
