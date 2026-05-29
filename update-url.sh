#!/bin/bash
# update-url.sh - cpolar启动后自动更新GitHub配置
# 使用方法: ./update-url.sh

set -e

# 配置信息
GITHUB_USERNAME="13798489127"
GITHUB_REPO="erp-redirect"
CONFIG_FILE="/Users/Admin/Projects/importTools/gitee-pages/config.json"
CPOLAR_LOG="/Users/Admin/Projects/importTools/cpolar.log"

# GitHub Token - 从环境变量读取，避免硬编码
# 设置方法: export GITHUB_TOKEN="your_token_here"
# 或创建 .env 文件: echo 'GITHUB_TOKEN=your_token' > .env
if [ -f "/Users/Admin/Projects/importTools/gitee-pages/.env" ]; then
    source "/Users/Admin/Projects/importTools/gitee-pages/.env"
fi

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}正在获取最新的cpolar URL...${NC}"

# 获取最新的cpolar URL
NEW_URL=$(cat "$CPOLAR_LOG" 2>/dev/null | grep -oE 'https?://[a-zA-Z0-9.-]+\.cpolar\.top' | tail -1)

if [ -z "$NEW_URL" ]; then
    echo -e "${RED}错误: 无法获取cpolar URL${NC}"
    echo "请确保cpolar正在运行: nohup cpolar http 3000 --log=stdout > cpolar.log 2>&1 &"
    exit 1
fi

echo -e "${GREEN}获取到URL: $NEW_URL${NC}"

# 更新本地config.json
cat > "$CONFIG_FILE" << EOF
{
    "targetUrl": "$NEW_URL",
    "updatedAt": "$(date +%Y-%m-%d)",
    "description": "ERP销售订单导入中转站 - cpolar隧道地址"
}
EOF

echo -e "${GREEN}本地配置已更新${NC}"

# 推送到GitHub
echo -e "${YELLOW}正在推送到GitHub...${NC}"

cd /Users/Admin/Projects/importTools/gitee-pages

# 检查是否有未提交的更改
if git diff --quiet config.json; then
    echo -e "${YELLOW}配置无变化，跳过推送${NC}"
    exit 0
fi

# 提交更改
git add config.json
git commit -m "Update URL: $NEW_URL"

# 如果配置了Token，使用HTTPS推送；否则使用SSH
if [ -n "$GITHUB_TOKEN" ]; then
    # 使用Token认证推送
    git push "https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git" main
else
    # 使用SSH推送（需要配置SSH key）
    git push origin main 2>/dev/null || {
        echo -e "${RED}推送失败！请配置以下任一方式:${NC}"
        echo ""
        echo "方式1: 配置 GitHub Personal Access Token"
        echo "  export GITHUB_TOKEN=\"your_token\""
        echo "  或创建 .env 文件: echo 'GITHUB_TOKEN=your_token' > .env"
        echo ""
        echo "方式2: 配置 SSH key"
        echo "  ssh-keygen -t ed25519 -C \"your_email@example.com\""
        echo "  然后将公钥添加到 GitHub: https://github.com/settings/keys"
        exit 1
    }
fi

echo -e "${GREEN}✓ GitHub配置已更新${NC}"
echo -e "${GREEN}✓ 访问地址: https://${GITHUB_USERNAME}.github.io/${GITHUB_REPO}/${NC}"
