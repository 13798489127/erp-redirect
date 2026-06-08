#!/bin/bash
# update-url.sh - cpolar启动后自动更新GitHub配置
# 使用方法: 
#   ./update-url.sh              # 从日志文件自动获取URL
#   ./update-url.sh --force URL  # 强制使用指定URL

set -e

# 配置信息
GITHUB_USERNAME="13798489127"
GITHUB_REPO="erp-redirect"
CONFIG_FILE="/Users/Admin/Projects/importTools/erp-redirect/config.json"
CPOLAR_LOG="/Users/Admin/Projects/importTools/cpolar.log"

# 解析参数
FORCE_MODE=false
NEW_URL=""

if [ "$1" = "--force" ] && [ -n "$2" ]; then
    FORCE_MODE=true
    NEW_URL="$2"
fi

# GitHub Token - 从环境变量读取，避免硬编码
# 设置方法: export GITHUB_TOKEN="your_token_here"
# 或创建 .env 文件: echo 'GITHUB_TOKEN=your_token' > .env
if [ -f "/Users/Admin/Projects/importTools/erp-redirect/.env" ]; then
    source "/Users/Admin/Projects/importTools/erp-redirect/.env"
fi

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 获取URL
if [ "$FORCE_MODE" = false ]; then
    log "${YELLOW}正在获取最新的cpolar URL...${NC}"
    
    # 确保日志文件存在
    if [ ! -f "$CPOLAR_LOG" ]; then
        log "${RED}错误: 日志文件不存在: $CPOLAR_LOG${NC}"
        log "请确保cpolar正在运行: launchctl load ~/Library/LaunchAgents/com.cpolar.plist"
        exit 1
    fi
    
    # 获取最新的cpolar URL
    NEW_URL=$(grep -oE 'https?://[a-zA-Z0-9.-]+\.cpolar\.(cn|top)' "$CPOLAR_LOG" 2>/dev/null | tail -1)
    
    if [ -z "$NEW_URL" ]; then
        log "${RED}错误: 无法获取cpolar URL${NC}"
        log "请确保cpolar正在运行: launchctl load ~/Library/LaunchAgents/com.cpolar.plist"
        exit 1
    fi
fi

log "${GREEN}获取到URL: $NEW_URL${NC}"

# 检查是否与当前配置相同
if [ -f "$CONFIG_FILE" ]; then
    CURRENT_URL=$(grep -o '"targetUrl": *"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
    if [ "$NEW_URL" = "$CURRENT_URL" ]; then
        log "${YELLOW}配置无变化，跳过更新${NC}"
        exit 0
    fi
fi

# 更新本地config.json
cat > "$CONFIG_FILE" << EOF
{
    "targetUrl": "$NEW_URL",
    "updatedAt": "$(date +%Y-%m-%d)",
    "description": "ERP销售订单导入中转站 - cpolar隧道地址"
}
EOF

log "${GREEN}本地配置已更新${NC}"

# 推送到GitHub
log "${YELLOW}正在推送到GitHub...${NC}"

cd /Users/Admin/Projects/importTools/erp-redirect

# 检查是否有未提交的更改
if git diff --quiet config.json 2>/dev/null; then
    log "${YELLOW}配置无变化，跳过推送${NC}"
    exit 0
fi

# 提交更改
git add config.json
git commit -m "Update URL: $NEW_URL [$(date '+%Y-%m-%d %H:%M:%S')]"

# 如果配置了Token，使用HTTPS推送；否则使用SSH
MAX_RETRIES=3
RETRY_DELAY=5

for i in $(seq 1 $MAX_RETRIES); do
    if [ -n "$GITHUB_TOKEN" ]; then
        # 使用Token认证推送
        if git push "https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git" main; then
            break
        fi
    else
        # 使用SSH推送（需要配置SSH key）
        if git push origin main 2>/dev/null; then
            break
        fi
    fi
    
    if [ $i -lt $MAX_RETRIES ]; then
        log "${YELLOW}推送失败，${RETRY_DELAY}秒后重试 ($i/$MAX_RETRIES)...${NC}"
        sleep $RETRY_DELAY
    else
        log "${RED}推送失败！已重试${MAX_RETRIES}次${NC}"
        echo ""
        echo "请配置以下任一方式:"
        echo ""
        echo "方式1: 配置 GitHub Personal Access Token"
        echo "  export GITHUB_TOKEN=\"your_token\""
        echo "  或创建 .env 文件: echo 'GITHUB_TOKEN=your_token' > .env"
        echo ""
        echo "方式2: 配置 SSH key"
        echo "  ssh-keygen -t ed25519 -C \"your_email@example.com\""
        echo "  然后将公钥添加到 GitHub: https://github.com/settings/keys"
        exit 1
    fi
done

log "${GREEN}✓ GitHub配置已更新${NC}"
log "${GREEN}✓ 访问地址: https://${GITHUB_USERNAME}.github.io/${GITHUB_REPO}/${NC}"