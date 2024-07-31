#!/usr/bin/env sh

echo "empty boot strap"

cd /app

git clone https://github.com/nailuoGG/taro-v4-template-starter.git

pnpm i
pnpm install -g @tarojs/cli

pnpm run build:weapp
