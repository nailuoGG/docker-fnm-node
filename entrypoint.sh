#!/usr/bin/env bash

PUID=${PUID:-911}
PGID=${PGID:-911}

groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc

groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc

chown -R abc:abc /app
chown -R abc:abc /config
chown -R abc:abc /scripts

eval "$(fnm env --use-on-cd)"
