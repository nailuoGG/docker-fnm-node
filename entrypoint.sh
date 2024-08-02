#!/usr/bin/env bash
#
PUID=${PUID:-911}
PGID=${PGID:-911}

groupmod -o -g "$PGID" jenkins
usermod -o -u "$PUID" jenkins

groupmod -o -g "$PGID" jenkins
usermod -o -u "$PUID" jenkins

chown -R jenkins:jenkins /app
chown -R jenkins:jenkins /config
chown -R jenkins:jenkins /scripts

usermod -a -G root jenkins

# 配置启动文件
file_path="/app/bootstrap.sh"

# 判断文件是否存在
if [ -f "$file_path" ]; then
    echo "文件 $file_path 存在。"
    chmod +x "$file_path"
    gosu jenkins bash -i "$file_path"
else
    echo "文件 $file_path 不存在。"
fi
