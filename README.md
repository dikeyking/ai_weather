# Weather App for macOS

一个简洁的 macOS 天气应用，使用 SwiftUI 构建，展示当前天气信息。

## 功能特性

### 已实现
- ✅ **定位权限管理**：请求和管理 macOS 定位权限
- ✅ **GPS 搜索**：支持搜索城市和地点
- ✅ **实时天气**：使用 Open-Meteo 免费 API 获取天气数据
- ✅ **分栏 UI**：
  - 左侧：城市列表，显示已保存的位置和温度快览
  - 右侧：选中城市的详细天气信息
- ✅ **SF Symbols**：使用系统图标显示天气状态
- ✅ **数据持久化**：城市列表保存到 UserDefaults
- ✅ **完整测试覆盖**：单元测试和集成测试

### 待实现（见 PLAN.md）
- ⏳ 内存缓存（快速响应）
- ⏳ 持久化缓存（跨重启保留）
- ⏳ 多天天气预报
- ⏳ 本地化支持
- ⏳ iOS 平台支持

## 项目结构

```
Weather/
├── PLAN.md                          # 项目计划和设计文档
├── Weather/
│   ├── WeatherApp.swift             # App 入口
│   ├── ContentView.swift            # 主视图（分栏布局）
│   ├── Models.swift                 # 数据模型和天气代码映射
│   ├── LocationManager.swift        # 定位服务封装
│   ├── WeatherService.swift         # 天气 API 服务
│   ├── WeatherViewModel.swift       # 视图模型
│   ├── Info.plist                   # 权限配置
│   └── Assets.xcassets/             # 资源文件
└── WeatherTests/
    ├── WeatherModelTests.swift      # 模型和映射测试 (TC3.x)
    ├── WeatherServiceTests.swift    # 天气服务测试 (TC1.x)
    ├── LocationManagerTests.swift   # 定位服务测试 (TC2.x)
    └── IntegrationTests.swift       # 集成测试 (TC4.x)
```

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI, Combine, CoreLocation
- **平台**: macOS 14.0+
- **架构**: MVVM (Model-View-ViewModel)
- **API**: [Open-Meteo](https://open-meteo.com) - 免费天气 API（无需 API key）
- **测试**: XCTest

## 安装与运行

### 前置要求
- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本

### 构建步骤

1. **克隆或打开项目**
   ```bash
   cd /Users/king/Developer/temp/Weather
   open Weather.xcodeproj
   ```

2. **在 Xcode 中配置**
   - 选择 target: Weather
   - 选择运行设备: My Mac (Designed for Mac)
   - 确认 Info.plist 包含定位权限描述

3. **构建并运行**
   - 快捷键: `Cmd + R`
   - 或点击 Xcode 工具栏的 Run 按钮

4. **首次运行**
   - 应用会请求定位权限
   - 授予权限后，会自动获取当前位置的天气
   - 使用搜索框添加更多城市

### 运行测试

在 Xcode 中运行所有测试：

```bash
# 命令行运行测试
xcodebuild test -scheme Weather -destination 'platform=macOS'
```

或在 Xcode 中：
- 快捷键: `Cmd + U`
- 或 Product → Test

### 测试覆盖率

已实现的测试用例（参见 PLAN.md）：

- **TC1.x**: WeatherService API 测试（正常流程、边界值、错误处理）
- **TC2.x**: LocationManager 测试（权限、搜索、地理编码）
- **TC3.x**: 数据模型测试（JSON 解析、天气代码映射、SF Symbols）
- **TC4.x**: 集成测试（完整流程、多城市、持久化）

## 使用指南

### 主要功能

1. **查看当前位置天气**
   - 点击底部 "Current Location" 按钮
   - 首次使用需授予定位权限

2. **搜索城市**
   - 在左侧搜索框输入城市名（如 "Tokyo", "Paris"）
   - 按 Enter 搜索
   - 点击搜索结果添加城市

3. **查看天气详情**
   - 点击左侧城市列表中的任意城市
   - 右侧显示详细天气信息：
     - 温度（摄氏度）
     - 天气图标和描述
     - 风速和风向
     - 更新时间

4. **刷新天气**
   - 右键点击城市 → "Refresh"
   - 或点击详情页的 "Refresh" 按钮

5. **删除城市**
   - 右键点击城市 → "Remove"

## API 说明

### Open-Meteo Weather API

- **端点**: `https://api.open-meteo.com/v1/forecast`
- **参数**:
  - `latitude`: 纬度
  - `longitude`: 经度
  - `current_weather`: true
  - `timezone`: auto
- **无需注册或 API key**
- **速率限制**: 合理使用（约 10,000 请求/天）

### 天气代码映射

| 代码 | 描述 | SF Symbol |
|------|------|-----------|
| 0 | Clear sky | sun.max.fill |
| 1-3 | Cloudy | cloud.sun.fill / cloud.fill |
| 45-48 | Fog | cloud.fog.fill |
| 51-57 | Drizzle | cloud.drizzle.fill |
| 61-67 | Rain | cloud.rain.fill |
| 71-77 | Snow | snow / cloud.snow.fill |
| 80-86 | Showers | cloud.heavyrain.fill |
| 95-99 | Thunderstorm | cloud.bolt.fill |

完整映射见 `Models.swift` 中的 `WeatherCode` enum。

## 故障排除

### 定位权限问题
- 确保 Info.plist 包含 `NSLocationWhenInUseUsageDescription`
- 在系统设置中检查 Weather 应用的定位权限
- macOS: 系统设置 → 隐私与安全性 → 定位服务

### 网络错误
- 检查网络连接
- Open-Meteo API 可能偶尔不可用
- 查看控制台日志以获取详细错误信息

### 搜索无结果
- 确认输入的城市名拼写正确
- 尝试使用英文城市名
- 某些偏远地区可能无法通过名称搜索

## 开发计划

详细的设计文档和后续计划请查看 [PLAN.md](PLAN.md)。

### 短期目标
- [ ] 添加内存缓存以减少 API 请求
- [ ] 实现 UserDefaults 持久化缓存
- [ ] 添加多天天气预报
- [ ] 优化 UI/UX（动画、过渡效果）

### 长期目标
- [ ] iOS 版本支持
- [ ] 本地化（中文、日文等）
- [ ] 天气地图集成
- [ ] Widget 支持
- [ ] iCloud 同步

## 许可证

本项目仅供学习和演示使用。

## 联系方式

有问题或建议？请参考 PLAN.md 或提交 issue。

---

**注意**: 本应用使用免费的 Open-Meteo API。请合理使用，避免过度请求。
