#!/usr/bin/env sh

echo "empty boot strap"

eval "$(fnm env --use-on-cd)"

cd /app || exit
pnpm i

pnpm install -g @tarojs/cli

pnpm run build:weapp
