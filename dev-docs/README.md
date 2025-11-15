# 开发文档目录

本目录包含项目开发过程中的技术文档、问题解决方案和配置说明。

## 文档索引

### 01. macOS 位置服务配置
**文件**: `01-macos-location-setup.md`  
**内容**: macOS 位置服务的基础配置、权限流程说明和开发版本特殊处理

### 02. macOS 权限解决方案
**文件**: `02-macos-permission-solution.md`  
**内容**: 深度解析 macOS 权限模型、iOS vs macOS 差异、根本问题和解决方案

### 03. Apple 官方文档修复
**文件**: `03-apple-docs-fixes.txt`  
**内容**: 基于 Apple 官方 CoreLocation 文档的权限实现，包含官方示例代码

### 04. 网络代理修复
**文件**: `04-network-proxy-fix.txt`  
**内容**: App Sandbox 网络权限配置、代理问题分析和 URLSession 配置

### 05. 网络修复说明
**文件**: `05-network-fix.txt`  
**内容**: entitlements 文件配置、网络客户端权限启用

### 06. 权限检查报告
**文件**: `06-permission-check-report.txt`  
**内容**: 完整的权限配置检查清单和验证步骤

## 文档使用指南

### 遇到权限问题时
1. 先查看 `02-macos-permission-solution.md` 了解 macOS 权限模型
2. 参考 `03-apple-docs-fixes.txt` 查看官方推荐实现
3. 使用 `06-permission-check-report.txt` 进行配置检查

### 遇到网络问题时
1. 查看 `04-network-proxy-fix.txt` 了解代理问题
2. 参考 `05-network-fix.txt` 检查 entitlements 配置
3. 确认 App Sandbox 网络权限已启用

### 开发新功能时
1. 查看项目根目录的 `ARCHITECTURE.md` 了解整体架构
2. 参考 `API_DOCUMENTATION.md` 了解 API 使用
3. 遵循 `TESTING_GUIDE.md` 编写测试

## 关键技术点

### macOS 权限特性
- macOS 上 When In Use 和 Always 授权功能等效
- macOS apps 启动后持续在后台运行
- 推荐使用 `requestWhenInUseAuthorization()`

### App Sandbox 配置
- 必须启用 `ENABLE_APP_SANDBOX = YES`
- 网络访问需要 `com.apple.security.network.client`
- 位置服务需要 `com.apple.security.personal-information.location`

### 代理处理
- URLSession 默认使用系统代理
- App Sandbox 阻止连接本地端口
- 通过 `connectionProxyDictionary = [:]` 禁用代理

## 更新历史

- **2025-11-15**: 初始创建，整理开发过程中的所有技术文档
