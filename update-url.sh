#!/bin/bash
# update-url.sh - cpolar启动后自动更新Gitee配置
# 使用方法: ./update-url.sh

set -e

# 配置信息
GITEE_USERNAME="DMysq"
GITEE_REPO="erp-redirect"
GITEE_TOKEN="1388de4fb726b682d8b990dcbbdf3d28"
CONFIG_FILE="/Users/Admin/Projects/importTools/gitee-pages/config.json"
CPOLAR_LOG="/Users/Admin/Projects/importTools/cpolar.log"

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

# 检查是否配置了Gitee Token
if [ -z "$GITEE_TOKEN" ]; then
    echo -e "${YELLOW}警告: 未配置Gitee Token，无法自动推送到Gitee${NC}"
    echo ""
    echo "请按以下步骤手动配置:"
    echo "1. 访问 https://gitee.com/personal_access_tokens 创建个人访问令牌"
    echo "2. 权限选择: projects"
    echo "3. 将令牌填入本脚本的 GITEE_TOKEN 变量"
    echo "4. 或者手动推送: cd /Users/Admin/Projects/importTools/gitee-pages && git add . && git commit -m 'Update URL' && git push"
    echo ""
    echo "手动推送命令:"
    echo "  cd /Users/Admin/Projects/importTools/gitee-pages"
    echo "  git add config.json"
    echo "  git commit -m 'Update URL: $NEW_URL'"
    echo "  git push origin master"
    exit 0
fi

# 通过Gitee API更新文件
echo -e "${YELLOW}正在推送到Gitee...${NC}"

# 获取文件的SHA（Gitee API更新文件需要）
CURRENT_CONTENT=$(curl -s "https://gitee.com/api/v5/repos/${GITEE_USERNAME}/${GITEE_REPO}/contents/config.json?access_token=${GITEE_TOKEN}")
SHA=$(echo "$CURRENT_CONTENT" | grep -o '"sha":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$SHA" ]; then
    echo -e "${RED}错误: 无法获取文件SHA，请检查Token权限${NC}"
    exit 1
fi

# Base64编码文件内容
CONTENT_BASE64=$(cat "$CONFIG_FILE" | base64)

# 更新文件
RESPONSE=$(curl -s -X PUT "https://gitee.com/api/v5/repos/${GITEE_USERNAME}/${GITEE_REPO}/contents/config.json" \
    -H "Content-Type: application/json" \
    -d "{
        \"access_token\": \"${GITEE_TOKEN}\",
        \"sha\": \"${SHA}\",
        \"content\": \"${CONTENT_BASE64}\",
        \"message\": \"Update URL: ${NEW_URL}\"
    }")

if echo "$RESPONSE" | grep -q '"sha"'; then
    echo -e "${GREEN}✓ Gitee配置已更新${NC}"
    echo -e "${GREEN}✓ 访问地址: https://${GITEE_USERNAME}.gitee.io/${GITEE_REPO}${NC}"
else
    echo -e "${RED}✗ 更新失败: $RESPONSE${NC}"
    exit 1
fi
