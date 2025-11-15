# macOS 位置权限设置指南

## 关键理解

1. **macOS vs iOS API 差异**：
   - iOS: 支持 `requestWhenInUseAuthorization()` 和 `requestAlwaysAuthorization()`
   - macOS: **只支持** `requestAlwaysAuthorization()`

2. **开发版本的特殊性**：
   - 从 Xcode 运行的开发版本有特殊的权限处理流程
   - 权限对话框会在首次访问位置时自动弹出
   - 需要在用户交互时（如点击"获取当前位置"按钮）触发

3. **System Settings 中看不到 app 的原因**：
   - 开发版本在运行期间不会作为已安装的 app 出现在系统设置中
   - 这是正常的，因为它是通过 Xcode 运行的临时 bundle

## 实现方式

### 代码中的平台条件编译

```swift
#if os(macOS)
locationManager.requestAlwaysAuthorization()  // macOS only
#else
locationManager.requestWhenInUseAuthorization()  // iOS
#endif
```

### Info.plist 配置

已包含以下权限描述：
- `NSLocationAlwaysUsageDescription` - macOS 需要
- `NSLocationWhenInUseUsageDescription` - iOS 需要
- `NSLocationAlwaysAndWhenInUseUsageDescription` - 备用

## 使用流程

1. 从 Xcode 运行应用
2. 应用启动后，点击界面上的 **"获取当前位置"** 按钮
3. 系统会弹出权限对话框：
   ```
   "Weather"想访问您的位置
   ```
4. 点击 **"始终允许"** 按钮
5. 权限被授予，应用开始获取天气数据

## 权限状态排查

如果权限对话框没有出现：

1. **检查是否已授予权限**：
   - 打开 System Preferences → Security & Privacy → Location Services
   - 确保启用了 Location Services
   - 注意：app 在 Xcode 开发运行时可能显示为 "Xcode"

2. **重置权限**（如需要）：
   ```bash
   # 在终端运行
   tccutil reset CoreLocationAccess com.apple.dt.Xcode
   ```

3. **清除 Xcode 缓存**：
   - 在 Xcode 中: Product → Clean Build Folder (Cmd+Shift+K)
   - 重新运行应用

4. **检查 Bundle Identifier**：
   - 确保应用的 Bundle ID 在 Xcode project settings 中正确配置
   - 路径: Project → Targets → General → Bundle Identifier

## 测试步骤

1. 清空之前的授权：
   ```bash
   tccutil reset CoreLocationAccess
   ```

2. 从 Xcode 运行应用

3. 应该看到位置权限对话框 (✓ 应该出现)

4. 授予权限后，点击"获取当前位置"

5. 应该看到天气数据显示

## 发布版本

当应用发布到 App Store 或作为 .app 文件分发时：
- 系统会自动处理权限流程
- 用户会在 System Preferences → Security & Privacy → Location Services 中看到应用名称
- 用户可以在那里管理权限

## 相关文件

- `LocationManager.swift` - 包含平台条件编译的权限请求逻辑
- `WeatherViewModel.swift` - 权限检查逻辑
- `Info.plist` - 权限描述字符串配置
