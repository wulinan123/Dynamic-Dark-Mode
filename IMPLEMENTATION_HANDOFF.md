# Dynamic Dark Mode 实现中断交接

## 当前状态

本次实现已中途停止，工作树处于**未完成且未验证可编译**状态。

当前 `git status --short` 涉及的文件：

- `Dynamic/Components/Appearance/AppleInterfaceStyle+NSAppearance.swift`
- `Dynamic/Components/Appearance/AppleInterfaceStyle.swift`
- `Dynamic/Components/Appearance/AppleScriptHelper.swift`
- `Dynamic/Components/AppleInterfaceStyle+Coordinator.swift`
- `Dynamic/Components/Preferences.swift`
- `Dynamic/Components/Scheduler/Scheduler.swift`
- `Dynamic/View Controller/Access Points/StatusBarItem.swift`
- `Dynamic/View Controller/AppDelegate.swift`
- `Dynamic/View Controller/Settings/DynamicDesktopSettingsViewController.swift`（已删除，尚未补回）
- `Dynamic/View Controller/Settings/SettingsViewController + TouchBar.swift`
- `Dynamic/View Controller/Settings/SettingsViewController.swift`
- `Dynamic/View Controller/Welcome/AllowLocationViewController.swift`
- `Dynamic/View Controller/Welcome/AllowSystemEventsViewController.swift`
- `Dynamic/View Controller/Welcome/InitialSetupViewController.swift`
- `Dynamic/View Controller/Welcome/SetupStep.swift`
- `Dynamic/View Controller/Welcome/SlideSegue.swift`
- `Dynamic/View Controller/Welcome/Welcome.swift`

## 已完成的部分

### 1. 新应用骨架已开始切换到 SwiftUI

- `SettingsViewController.swift` 已改为 `@main struct DynamicDarkModeApp: App`
- `AppDelegate.swift` 已移除 `@NSApplicationMain` 用法，并新增：
  - `AppUpdater`
  - `AppBootstrapper`
  - `reopen()` 新路由入口

### 2. 新窗口路由骨架已建立

- `Welcome.swift` 新增了 `WindowRouter`
- 目标方向已改为：
  - 设置窗口走 SwiftUI `Settings` scene
  - 首次启动向导走 `NSHostingController` + SwiftUI view

### 3. 外观状态同步链路已开始重写

- `AppleInterfaceStyle+NSAppearance.swift` 新增了 `AppearanceMonitor`
- `AppleScriptHelper.swift` 已改为带 completion 的切换路径，并在切换后主动刷新 monitor
- `StatusBarItem.swift` 已切到 SF Symbols：
  - 深色：`moon.fill`
  - 浅色：`sun.max.fill`
- `StatusBarItem.swift` 已改为订阅 `AppearanceMonitor.shared.$currentStyle`

### 4. 新设置界面和新向导界面已有初版结构

- `SettingsViewController.swift` 已有 4 个 tab 的初版：
  - `GeneralSettingsTab`
  - `AutomationSettingsTab`
  - `DesktopSettingsTab`
  - `AboutSettingsTab`
- `SettingsViewController + TouchBar.swift` 已有支持视图：
  - `SettingsPaneScroll`
  - `SettingsCard`
  - `WindowAccessor`
  - `ShortcutRecorderView`
- `Welcome` 相关文件已初步改成 SwiftUI 向导结构：
  - `OnboardingFlowModel`
  - `OnboardingFlowView`
  - `WelcomeStepView`
  - `AutomationPermissionStepView`
  - `LocationPermissionStepView`
  - `OnboardingStepCard`
  - `OnboardingBackdrop`

## 明确未完成 / 当前已知会出问题的点

### A. 当前最直接的编译阻塞

1. `Dynamic/View Controller/Settings/DynamicDesktopSettingsViewController.swift` 已被删除，但还没有重建。
   当前 `SettingsViewController.swift` 仍引用了以下未定义类型/符号：
   - `DynamicDesktopSettingsViewController.selectImage`
   - `DynamicDesktopPanelView`
   - `DesktopPreviewRow`

2. `Dynamic/Components/AppleInterfaceStyle+Coordinator.swift` 里这段通知观察代码的 closure 签名是错的：

   - 当前写法：`{ _, _ in ... }`
   - `NotificationCenter.default.addObserver(forName:object:queue:using:)` 只会传一个 `Notification`

3. 当前没有做任何真实编译验证。
   之前环境里 `xcodebuild` 不可用，因为系统只指向 Command Line Tools，没有完整 Xcode。

### B. 工程入口和配置还没切完

1. `Dynamic/Supporting Files/Info.plist` 还没改。
   目前仍保留：

   - `NSMainStoryboardFile = Main`

   如果继续走 SwiftUI `@main` 入口，这个键需要处理掉。

2. `Dynamic Dark Mode.xcodeproj/project.pbxproj` 还没改。
   计划里的这些点都还没做：

   - `MACOSX_DEPLOYMENT_TARGET` 提升到 `15.0`
   - 如有必要，清理旧 storyboard 作为主入口的假设
   - 如需同步版本策略，`Tools/main.swift` 里的 appcast 最低系统版本仍是 `10.14`

### C. 本地化还没接

新 SwiftUI 界面已经写入了大量新的 `NSLocalizedString` key，但当前：

- `zh-Hans.lproj/Localizable.strings` 还没补这些新 key
- 英文只是靠 `value:` fallback
- 计划要求的“本轮只交付英文和简体中文”还没完成

重点待补前缀：

- `Settings.*`
- `Onboarding.*`
- `SystemPreferences.open`
- `SystemPreferences.skip`

### D. Desktop / 壁纸子系统只改了一半

计划中的 Desktop 面板尚未完成：

- 需要补回 SwiftUI 的 `DynamicDesktopPanelView`
- 需要补 `DesktopPreviewRow`
- 需要把原来 `NSOpenPanel` 选图逻辑迁回新的 helper
- 需要确认新面板与 `preferences.lightDesktopURL` / `preferences.darkDesktopURL` 的写回仍兼容现有格式

### E. Settings scene 只是结构完成，还没做收尾验证

虽然 `SettingsViewController.swift` 已有 tab 和表单骨架，但还没做这些确认：

- `WindowRouter.showSettings()` 通过 `showSettingsWindow:` / `showPreferencesWindow:` 能否稳定拉起 SwiftUI `Settings` scene
- `WindowAccessor` 是否能稳定拿到 settings window 并写入 identifier
- `MASShortcutView.associatedUserDefaultsKey` 在当前依赖版本里是否可直接用
- `AppUpdater` 对 `Sparkle` 的 API 调用是否与当前包版本完全一致

### F. 首次启动向导还没做行为收尾

向导结构已改，但还没收尾这些行为：

- welcome / automation / location 的视觉细节还没调
- 关闭 onboarding window 后是否需要自动重新拉起，目前只保留了下次 reopen 再打开
- `finishOnboarding()` 之后是否需要补更多初始化动作，需要完整回归

### G. 旧 storyboard / 旧 controller 尚未彻底清理

当前是“新代码已开始接管，但旧资源还在”的状态：

- `Base.lproj/Main.storyboard` 仍在工程里
- 旧 storyboard 自定义类引用还在
- 未决定最终是保留资源但不使用，还是从 target 中剔除

## 建议恢复顺序

建议按下面顺序继续，而不是分散收尾：

1. 先补回 `DynamicDesktopSettingsViewController.swift`
   - 至少恢复 `selectImage`
   - 新增 `DynamicDesktopPanelView`
   - 新增 `DesktopPreviewRow`

2. 修正当前显式编译错误
   - `AppleInterfaceStyle+Coordinator.swift` 的通知 closure
   - 所有未定义类型/符号

3. 再处理入口切换
   - 修改 `Info.plist`
   - 修改 `project.pbxproj`
   - 将最低系统版本提升到 `macOS 15.0`

4. 再补本地化
   - 先补英文 fallback 对应 key 设计
   - 再补 `zh-Hans.lproj/Localizable.strings`

5. 最后做验证
   - 真机构建
   - 首次启动向导流程
   - Settings 四个 tab
   - 状态栏图标同步
   - Sparkle 手动/自动更新
   - 动态壁纸选择与清除

## 推荐首先检查的文件

- [AppDelegate.swift](/Users/nan/Documents/FILE/1-项目/Dynamic-Dark-Mode/Dynamic/View%20Controller/AppDelegate.swift)
- [SettingsViewController.swift](/Users/nan/Documents/FILE/1-项目/Dynamic-Dark-Mode/Dynamic/View%20Controller/Settings/SettingsViewController.swift)
- [Welcome.swift](/Users/nan/Documents/FILE/1-项目/Dynamic-Dark-Mode/Dynamic/View%20Controller/Welcome/Welcome.swift)
- [SetupStep.swift](/Users/nan/Documents/FILE/1-项目/Dynamic-Dark-Mode/Dynamic/View%20Controller/Welcome/SetupStep.swift)
- [AppleInterfaceStyle+NSAppearance.swift](/Users/nan/Documents/FILE/1-项目/Dynamic-Dark-Mode/Dynamic/Components/Appearance/AppleInterfaceStyle+NSAppearance.swift)
- [StatusBarItem.swift](/Users/nan/Documents/FILE/1-项目/Dynamic-Dark-Mode/Dynamic/View%20Controller/Access%20Points/StatusBarItem.swift)
- [Preferences.swift](/Users/nan/Documents/FILE/1-项目/Dynamic-Dark-Mode/Dynamic/Components/Preferences.swift)

## 备注

- 当前中断前**没有执行任何格式化**。
- 当前中断前**没有执行任何构建或测试**。
- 如果要继续，建议先让工作树回到“能编译”的最小状态，再继续做视觉和交互打磨。
