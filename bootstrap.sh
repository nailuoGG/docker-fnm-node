#!/usr/bin/env sh

echo "empty boot strap"

cd /app || exit
pnpm i

pnpm install -g @tarojs/cli

pnpm run build:weapp
