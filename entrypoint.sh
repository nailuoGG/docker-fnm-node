#!/usr/bin/env bash

PUID=${PUID:-911}
PGID=${PGID:-911}

groupmod -o -g "$PGID" jenkins
usermod -o -u "$PUID" jenkins

groupmod -o -g "$PGID" jenkins
usermod -o -u "$PUID" jenkins

chown -R jenkins:jenkins /app
chown -R jenkins:jenkins /config
chown -R jenkins:jenkins /scripts

eval "$(fnm env --use-on-cd)"
