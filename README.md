# erp-redirect

ERP销售订单导入中转站 - 自动重定向服务

## 功能

当访问 GitHub Pages 地址时，自动重定向到 cpolar 隧道地址。

## 自动更新机制

### 架构

```
cpolar (launchd) → cpolar.log → watch-cpolar.sh (tail -f) → update-url.sh → GitHub
```

### 组件

1. **cpolar** - 通过 `~/Library/LaunchAgents/com.cpolar.plist` 管理
   - 自动启动，系统启动时运行
   - 日志输出到 `/Users/Admin/Projects/importTools/cpolar.log`

2. **watch-cpolar.sh** - 监听脚本
   - 通过 `~/Library/LaunchAgents/com.cpolar-watch.plist` 管理
   - 使用 `tail -f` 实时监控 cpolar 日志
   - 检测到新 URL 时自动触发更新

3. **update-url.sh** - 更新脚本
   - 更新本地 `config.json`
   - 推送到 GitHub

### 手动操作

```bash
# 查看服务状态
launchctl list | grep cpolar

# 启动/停止 cpolar
launchctl load ~/Library/LaunchAgents/com.cpolar.plist
launchctl unload ~/Library/LaunchAgents/com.cpolar.plist

# 启动/停止监听服务
launchctl load ~/Library/LaunchAgents/com.cpolar-watch.plist
launchctl unload ~/Library/LaunchAgents/com.cpolar-watch.plist

# 手动触发更新
./update-url.sh
./update-url.sh --force https://xxx.cpolar.top

# 查看日志
tail -f /Users/Admin/Projects/importTools/cpolar.log
tail -f watch.log
```

### 故障排查

1. **cpolar 无日志输出**
   - 检查 plist 是否包含 `--log=stdout` 参数
   - 重启 cpolar: `launchctl unload/load ~/Library/LaunchAgents/com.cpolar.plist`

2. **监听脚本未触发更新**
   - 检查 watch.log 日志
   - 确认 watch-cpolar.sh 有执行权限: `chmod +x watch-cpolar.sh`

3. **GitHub 推送失败**
   - 配置 Token: `export GITHUB_TOKEN="your_token"`
   - 或配置 SSH key

## 文件结构

```
erp-redirect/
├── config.json          # 当前 cpolar URL 配置
├── index.html           # GitHub Pages 重定向页面
├── update-url.sh        # 更新脚本
├── watch-cpolar.sh      # 监听脚本
├── watch.log            # 监听脚本日志
├── watch-error.log      # 监听脚本错误日志
└── README.md            # 本文件
```

## 访问地址

https://13798489127.github.io/erp-redirect/