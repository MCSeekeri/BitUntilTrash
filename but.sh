#!/bin/bash

# 指定要压缩的目录
SOURCE="/path"
# 指定压缩后的文件名
OUTPUT="/path/archive_$(date +\%Y\%m\%d\%H\%M\%S).tar.zst"

function show_help {
    echo "用法: $0 [OPTION]"
    echo "参数:"
    echo "  -h, --help       输出帮助信息"
    echo "  --init-cron      初始化 cron 配置"
    echo "  --init-systemd   初始化 Systemd Timer 配置"
    exit 0
}
function default_action {
    tar --zstd -cf "$OUTPUT" "$SOURCE"
    echo "压缩完成: $OUTPUT"
}
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    elif [[ "$1" == "--init-cron" ]]; then
    CRON_JOB="0 * * * * /bin/bash $(dirname "$0")/but.sh"
    if ! crontab -l | grep -q "$CRON_JOB"; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo "Cron 配置成功添加"
    else
        echo "Cron 配置已存在"
    fi
    elif [[ "$1" == "--init-systemd" ]]; then
    SERVICE_FILE="/etc/systemd/system/but-archive.service"
    TIMER_FILE="/etc/systemd/system/but-archive.timer"
  cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=But it's just another file backup tool.

[Service]
Type=oneshot
ExecStart=/bin/bash $(realpath "$0")
EOF
  cat <<EOF | sudo tee "$TIMER_FILE" > /dev/null
[Unit]
Description=Run the archive script every minute

[Timer]
OnCalendar=*:0/1
Persistent=true

[Install]
WantedBy=timers.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable --now but-archive.timer
    echo "Systemd Timer 配置成功添加"
else
    default_action
fi
