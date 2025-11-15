# 快速参考

## 文件结构

```
Weather/
├── PLAN.md                    # 设计文档（需求、API、测试计划、缓存设计）
├── README.md                  # 使用指南（安装、运行、功能说明）
├── IMPLEMENTATION.md          # 实现总结（已完成功能、测试覆盖）
│
├── Weather/                   # 主应用代码
│   ├── WeatherApp.swift       # App 入口点
│   ├── ContentView.swift      # 主 UI（分栏布局）
│   ├── Models.swift           # 数据模型 + 天气代码映射
│   ├── LocationManager.swift  # 定位服务（权限、搜索、GPS）
│   ├── WeatherService.swift   # 天气 API（Open-Meteo）
│   ├── WeatherViewModel.swift # ViewModel（MVVM）
│   ├── Info.plist            # 定位权限配置
│   └── Assets.xcassets/       # 资源文件
│
└── WeatherTests/              # 测试套件（36 个测试用例）
    ├── WeatherModelTests.swift      # TC3.x - 模型和映射
    ├── WeatherServiceTests.swift    # TC1.x - API 服务
    ├── LocationManagerTests.swift   # TC2.x - 定位服务
    └── IntegrationTests.swift       # TC4.x - 集成测试
```

## 核心 API

### LocationManager
```swift
// 请求定位权限
locationManager.requestPermission()

// 搜索位置
let results = try await locationManager.searchLocation(query: "Tokyo")

// 获取位置名称
let name = try await locationManager.getLocationName(for: coordinate)
```

### WeatherService
```swift
// 获取天气
let weather = try await weatherService.fetchCurrentWeather(
    latitude: 35.6762,
    longitude: 139.6503
)
```

### WeatherViewModel
```swift
// 搜索并添加城市
viewModel.searchQuery = "Paris"
await viewModel.searchLocation()
await viewModel.addLocation(searchResults.first!)

// 刷新天气
await viewModel.refreshWeather(for: location)

// 删除城市
viewModel.removeLocation(location)
```

## 天气代码映射

```swift
// 获取 SF Symbol
let symbol = WeatherCode.sfSymbolName(for: weatherCode)
// 0 → "sun.max.fill"
// 61 → "cloud.rain.fill"
// 95 → "cloud.bolt.fill"

// 获取描述
let description = WeatherCode.description(for: weatherCode)
// 0 → "Clear sky"
// 61 → "Light rain"
```

## 常用命令

### 构建和运行
```bash
# 打开项目
open Weather.xcodeproj

# 在 Xcode 中: Cmd + R
```

### 运行测试
```bash
# 在 Xcode 中: Cmd + U

# 命令行
xcodebuild test -scheme Weather -destination 'platform=macOS'
```

### 查看日志
```bash
# 在 Xcode 中查看控制台输出
# 或使用 Console.app 查看系统日志
```

## UI 组件

### 主视图结构
```
ContentView
├── NavigationSplitView
│   ├── CityListView (左侧)
│   │   ├── 搜索框
│   │   ├── 搜索结果列表
│   │   ├── 已保存城市列表
│   │   └── "Current Location" 按钮
│   │
│   └── WeatherDetailView (右侧)
│       ├── 加载状态 (ProgressView)
│       ├── 错误状态 (错误信息 + 重试按钮)
│       ├── 空状态 ("选择一个位置")
│       └── WeatherContentView (天气详情)
│           ├── 城市名 + 更新时间
│           ├── 天气图标 (SF Symbol)
│           ├── 温度 (大号)
│           ├── 天气描述
│           ├── 风速 + 风向
│           └── 刷新按钮
```

## 测试用例速查

### 模型测试 (TC3.x)
- ✅ 天气代码映射（晴、云、雨、雪、雷暴）
- ✅ JSON 解析
- ✅ 字段完整性
- ✅ 数据类型验证

### 服务测试 (TC1.x)
- ✅ 正常请求
- ✅ 边界值（纬度 ±90、经度 ±180）
- ✅ 无效坐标
- ✅ 真实 API 集成

### 定位测试 (TC2.x)
- ✅ 授权状态
- ✅ 搜索功能（有效/无效/空查询）
- ✅ 反向地理编码
- ✅ 权限管理

### 集成测试 (TC4.x)
- ✅ 完整流程（搜索 → 添加 → 显示）
- ✅ 多城市管理
- ✅ 刷新和删除
- ✅ 持久化
- ✅ 防重复

## 环境要求

- **macOS**: 14.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+

## API 限制

- **Open-Meteo**: ~10,000 请求/天
- **无需 API key**
- **免费使用**

## 常见问题

**Q: 定位权限被拒绝怎么办？**
A: 系统设置 → 隐私与安全性 → 定位服务 → Weather → 启用

**Q: 搜索不到城市？**
A: 尝试使用英文城市名或包含国家（如 "Paris, France"）

**Q: 天气数据不更新？**
A: 点击刷新按钮或删除后重新添加城市

**Q: 测试失败？**
A: 确保网络连接正常，Open-Meteo API 可访问

## 下一步

1. 查看 `PLAN.md` 了解完整设计
2. 阅读 `README.md` 学习使用方法
3. 查看 `IMPLEMENTATION.md` 了解已完成功能
4. 运行测试验证功能
5. 开始开发新功能（见 PLAN.md 后续改进清单）

## 关键特性

- 🌍 多城市天气查看
- 📍 GPS 定位支持
- 🔍 城市搜索
- 💾 自动保存城市列表
- 🎨 SF Symbols 天气图标
- ⚡️ Async/await API
- ✅ 完整测试覆盖
- 📱 macOS 原生体验
