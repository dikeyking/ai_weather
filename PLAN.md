# Weather App Plan

这是用于将当前工程改造成一个简洁天气应用的讨论与实现计划文档。我们先在此讨论并确认方案，然后再一次性修改代码。

## 目标
1. 获取并使用本地定位权限（显示用户当前位置）。
2. 使用一个 async/await 风格的 `WeatherService` 类，调用免费的天气 API 获取当前天气数据。
3. 使用系统 SF Symbols 显示温度和天气（晴、雨、云等）。
4. 支持 GPS 搜索以查看不同位置的天气。
5. 实现分栏 UI（左边城市列表，右边天气详情）。
6. 编写完整的测试用例，保证各个 test case 通过。

## 约束与假设
- 目标平台：**macOS (SwiftUI)**，确保跨平台可用性，iOS 在后续考虑。
- 优先使用无需 API key 的免费 API：推荐 Open-Meteo（https://open-meteo.com），它支持经纬度查询并返回温度和天气代码。
- 使用 CoreLocation 请求定位权限并取得经纬度。
- 使用 SF Symbols（系统图标）来显示天气图标和温度等。

## API 选择与数据契约
### Open-Meteo (推荐)
- 接口示例：`https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true&timezone=auto`
- 响应示例片段：
  - `current_weather.temperature` (°C)
  - `current_weather.weathercode` (整数，代表天气类型)
  - `current_weather.windspeed`

契约（WeatherModel）输入/输出：
- 输入：latitude: Double, longitude: Double
- 输出：struct Weather { temperature: Double, weatherCode: Int, windSpeed: Double, time: Date }

错误模式：网络错误、解析错误、无权限无法定位、API 返回异常数据。

## 定位权限流程（LocationManager）
- 使用 `CLLocationManager`，封装在 `ObservableObject` 的 `LocationManager` 中。
- 提供：
  - @Published var authorizationStatus: CLAuthorizationStatus
  - @Published var lastLocation: CLLocation?
  - 方法 `requestPermission()`，`startUpdating()`，`stopUpdating()`。
- Edge cases：用户拒绝、临时授权受限、模拟器无定位时的回退体验（允许手动输入经纬度或选择城市，在首轮实现中显示友好信息）。

## WeatherService 设计
- `class WeatherService { func fetchCurrentWeather(lat: Double, lon: Double) async throws -> Weather }`
- 使用 URLSession.data(for:request) async API。
- 解析 JSON 到内部模型（使用 Codable）。
- 可扩展：未来可加入缓存、背景刷新、多天预报。

## 天气代码到 SF Symbols 映射
- Open-Meteo 的 weathercode 文档会列出代码含义，示例映射：
  - 0 -> sun.max
  - 1,2,3 -> cloud.sun
  - 45,48 -> fog
  - 51,53,55,56,57 -> cloud.drizzle
  - 61,63,65,66,67 -> cloud.rain
  - 71,73,75 -> snow
  - 95,96,99 -> cloud.bolt.rain
- 我们会实现一个函数 `sfSymbolName(forWeatherCode:) -> String` 返回 SF Symbol 名称。

## UI 建议（初稿）
- **分栏设计**（二栏布局）：
  - **左栏**：城市列表，展示已搜索或关注的城市及其温度快览。支持搜索框以添加新城市（GPS 搜索）。
  - **右栏**：所选城市的天气详情，包含温度（大号）、天气图标（SF Symbol）、风速、更新时间等。
- 状态处理视图：
  - 加载中：ProgressView 与占位图。
  - 无权限：展示说明与"请求权限"按钮（macOS 将调用系统设置）。
  - 错误：展示错误描述与"重试"按钮。
  - 无数据：默认显示用户当前位置天气（若有权限）。
- 布局示例（右栏）：
  - 顶部：城市名、更新时间。
  - 中间：大温度（例如 22°）和 SF Symbol。
  - 底部：风速、更多详情。

视觉风格：简洁、使用系统颜色和 SF Symbol。macOS 风格遵循 Human Interface Guidelines。

## 测试计划
### API 与测试用例列表
以下是本项目涉及的核心 API 及其对应的测试用例：

#### 1. WeatherService API
- **API**: `fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather`
  - **输入**: 经度、纬度
  - **输出**: Weather 结构体（温度、天气代码、风速、时间戳等）
  - **测试用例**：
    - ✓ TC1.1：正常请求有效坐标，返回有效天气数据
    - ✓ TC1.2：API 返回无效 JSON，捕获解析错误
    - ✓ TC1.3：网络不可达，捕获网络错误
    - ✓ TC1.4：API 返回错误状态码（4xx/5xx），捕获 HTTP 错误
    - ✓ TC1.5：经纬度边界值测试（-90, 90 / -180, 180）
    - ✓ TC1.6：响应超时处理（可选，需配置超时）

#### 2. LocationManager API
- **API**: `requestLocationPermission() async -> CLAuthorizationStatus`
  - **输出**: 授权状态（已授权、已拒绝、未确定）
  - **测试用例**：
    - ✓ TC2.1：用户授予权限，返回 `.authorizedAlways`
    - ✓ TC2.2：用户拒绝权限，返回 `.denied`
    - ✓ TC2.3：未请求权限前状态为 `.notDetermined`
    - ✓ TC2.4：权限状态变化回调触发更新

- **API**: `startLocationUpdates() -> AnyPublisher<CLLocation, Never>`
  - **输出**: 持续发布位置更新
  - **测试用例**：
    - ✓ TC2.5：成功获取一次位置
    - ✓ TC2.6：位置更新触发订阅者更新
    - ✓ TC2.7：定位失败时发送错误回调（`didFailWithError`）

- **API**: `searchLocation(query: String) async throws -> [LocationResult]`（GPS 搜索）
  - **输入**: 城市名或地址字符串
  - **输出**: 匹配的位置列表（城市名、坐标）
  - **测试用例**：
    - ✓ TC2.8：搜索已知城市（例如"北京"），返回结果列表
    - ✓ TC2.9：搜索不存在的地点，返回空列表
    - ✓ TC2.10：搜索查询为空或特殊字符，处理输入验证
    - ✓ TC2.11：搜索 API 超时或网络错误，捕获异常

#### 3. 数据模型与映射
- **API**: `sfSymbolName(forWeatherCode: Int) -> String`
  - **输入**: Open-Meteo 天气代码
  - **输出**: SF Symbol 名称
  - **测试用例**：
    - ✓ TC3.1：映射晴天（code 0 → "sun.max"）
    - ✓ TC3.2：映射多云（code 1,2,3 → "cloud.sun"）
    - ✓ TC3.3：映射下雨（code 61,63,65 → "cloud.rain"）
    - ✓ TC3.4：映射下雪（code 71,73,75 → "snow"）
    - ✓ TC3.5：映射雷暴（code 95,96,99 → "cloud.bolt.rain"）
    - ✓ TC3.6：未知代码返回默认值（"cloud"）

- **Model**: Weather 结构体
  - **测试用例**：
    - ✓ TC3.7：JSON 解码测试（提供 sample Open-Meteo 响应）
    - ✓ TC3.8：字段完整性验证（无缺失字段）
    - ✓ TC3.9：数据类型验证（温度为 Double，代码为 Int 等）

#### 4. 集成测试
- **场景**: 完整流程
  - ✓ TC4.1：获取用户权限 → 获取当前坐标 → 请求天气 → 映射图标 → UI 显示
  - ✓ TC4.2：搜索城市 → 获取坐标 → 请求天气 → 添加到列表
  - ✓ TC4.3：权限拒绝时，提示用户并允许手动输入坐标或搜索

### 单元测试与集成测试框架
- 使用 XCTest（Apple 原生测试框架）。
- Mock Open-Meteo API 响应（使用 URLSession 的 URLProtocol 或 mock 库）。
- Mock CLLocationManager（创建测试代理或依赖注入）。
- 所有 async/await 测试使用 `XCTestExpectation` 或 `await` 直接调用。

### 测试文件结构
```
Weather/
  ├── Tests/
  │   ├── WeatherServiceTests.swift       # TC1.x
  │   ├── LocationManagerTests.swift      # TC2.x
  │   ├── WeatherModelTests.swift         # TC3.x
  │   └── IntegrationTests.swift          # TC4.x
  └── ...
```

## 实现迭代计划
1. ✓ 创建 `LocationManager`（CoreLocation 封装，支持定位与搜索）并在 UI 显示授权状态。
2. ✓ 实现 `WeatherService` 与 `Models`（Open-Meteo API 集成，async/await）。
3. ✓ 实现图标映射函数 `sfSymbolName(forWeatherCode:)`。
4. ✓ 修改 `ContentView` 实现分栏 UI（左城市列表，右天气详情）。
5. ✓ 编写完整单元测试（WeatherService、LocationManager、模型、集成测试）。
6. ✓ 手动测试定位权限流程与天气请求（macOS 模拟器/真机）。
7. 后续：实现缓存、多天预报、本地化等。

## 待确认项（已确认 / 已完成调整）
- ✅ 目标平台：macOS（跨平台兼容，iOS 后续）。
- ✅ 不需要支持华氏度切换（仅摄氏度）。
- ✅ UI 分栏设计（左城市列表，右天气详情）。
- ✅ 支持 GPS 搜索（LocationManager 提供搜索接口）。
- ✅ 暂不实现缓存，但提供缓存方案设计（见下）。
- ✅ 包含完整测试用例列表（见测试计划章节）。

## 缓存方案设计（待实现，列入后续 Todo）
当前未实现缓存功能，建议后续采用以下方案：

### 本地存储策略
1. **短期缓存**（内存）
   - 使用 @StateObject + @Published 在 app 运行时缓存天气数据。
   - 每个城市缓存最后一次请求的天气数据和时间戳。
   - 优势：快速响应、无磁盘 I/O。
   - 劣势：应用退出后丢失。

2. **持久化缓存**（UserDefaults / Codable + 文件系统）
   - 将城市列表和每个城市的最后天气数据序列化保存到 UserDefaults 或本地 JSON 文件。
   - 优势：跨应用重启保留、易于实现。
   - 劣势：容量限制、需手动序列化。

3. **高级方案**（Core Data / SQLite）
   - 如果未来要支持多用户、复杂查询、大数据量可考虑。
   - 当前项目不推荐（过度设计）。

### 过期策略
- 设定 TTL（Time To Live），例如 10 分钟。
- 若缓存未过期且可离线时使用缓存；否则重新请求。
- 用户可手动"刷新"按钮强制更新。

### 同步策略
- 后台定时刷新（可选）：使用 Timer 或 URLSessionBackgroundTask。
- 当前版本不实现，列为后续增强。

---

## 后续改进清单（待办项）
- [ ] 实现内存缓存（快速响应，应用内有效）。
- [ ] 实现 UserDefaults 持久化缓存（跨重启保留）。
- [ ] 后台定时刷新（DispatchSourceTimer）。
- [ ] 离线模式支持（缓存有效时使用）。
- [ ] 多天天气预报（API 支持，UI 展示）。
- [ ] 城市收藏与排序。
- [ ] 本地化国际化（多语言）。
- [ ] 深色模式支持优化。
- [ ] 性能优化与内存管理审计。
