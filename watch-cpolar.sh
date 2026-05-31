#!/bin/bash
# watch-cpolar.sh - 监听 cpolar 日志变化，自动更新 GitHub 配置
# 当 cpolar 重启或 URL 变化时自动触发更新

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CPOLAR_LOG="/Users/Admin/Projects/importTools/cpolar.log"
UPDATE_SCRIPT="$SCRIPT_DIR/update-url.sh"
LAST_URL_FILE="$SCRIPT_DIR/.last-url"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 确保日志文件存在
touch "$CPOLAR_LOG"

log "${GREEN}cpolar 监听服务已启动${NC}"
log "${YELLOW}监听文件: $CPOLAR_LOG${NC}"

# 获取上次更新的 URL
LAST_URL=""
if [ -f "$LAST_URL_FILE" ]; then
    LAST_URL=$(cat "$LAST_URL_FILE")
fi

# 使用 tail -f 实时监控日志
tail -n 0 -f "$CPOLAR_LOG" | while read -r line; do
    # 只匹配 https URL（避免 http/https 重复触发）
    if echo "$line" | grep -qE 'https://[a-zA-Z0-9.-]+\.cpolar\.(cn|top)'; then
        NEW_URL=$(echo "$line" | grep -oE 'https://[a-zA-Z0-9.-]+\.cpolar\.(cn|top)' | head -1)
        
        # 去重：跳过相同的 URL
        if [ "$NEW_URL" = "$LAST_URL" ]; then
            continue
        fi
        
        log "${GREEN}检测到新 URL: $NEW_URL${NC}"
        
        # 调用更新脚本
        if [ -x "$UPDATE_SCRIPT" ]; then
            log "${YELLOW}正在执行更新...${NC}"
            if "$UPDATE_SCRIPT" --force "$NEW_URL"; then
                log "${GREEN}更新成功${NC}"
                LAST_URL="$NEW_URL"
                echo "$NEW_URL" > "$LAST_URL_FILE"
            else
                log "${RED}更新失败${NC}"
            fi
        else
            log "${RED}错误: 更新脚本不存在或不可执行: $UPDATE_SCRIPT${NC}"
        fi
    fi
done