# LogQuick UI Library (`logz-ui-lib`)

> 高级 Roblox 注入器通用单文件 Luau UI 框架库  
> **作者**: Log_quick (固定不可篡改署名)

---

## 🌟 项目特性概炼 (Features Overview)

1. **📱 手机 / 💻 电脑 双端智能适配**
   - **手机端**：自动适配小屏幕尺寸、扩展触控判定响应区域、启用横向自适应 ScrollingTabBar。
   - **电脑端**：保持固定标准 560x440 像素高清精致比例与精确视口拖拽。

2. **🛠️ 内置全功能 UI 设置面板 (内置 Settings Panel)**
   - **Config 持久化**：JSON 文件的自动读写与反序列化（基于 `writefile` / `readfile`）。
   - **透明度调节**：实时玻璃感透明度调配。
   - **发光边框灯效**：支持 `Static`（静态）、`Rainbow`（彩虹渐变）、`Breathing`（呼吸）、`Pulse`（脉冲发光）。
   - **预设主题 & HSV 色盘**：`Dark`（暗色）、`Light`（亮色）、`Cyberpunk`（赛博朋克）、`Emerald`（翡翠绿）、`Sunset`（落日橙）、`Midnight`（深夜蓝），并附带 **2D HSV 自定义拾色盘**。
   - **音效系统**：全交互清脆 Sound 反馈、音量控制与自定义 Asset ID。
   - **作者与脚本版权**：内置固定 `UI 框架作者: Log_quick (不可更改)`，并提供 API 供脚本作者展示 independent 署名。

3. **🧩 完整组件与高级 API 列表 (Complete APIs)**
   - 🔘 **按钮 (Button)**：悬停/点击平滑动画。
   - 🔘 **开关 (Toggle)**：平滑滑动 Knob 视觉反馈。
   - 🎚️ **滑块 (Slider)**：数值步长 (Rounding)、最小值/最大值/单位后缀。
   - 🎨 **HSV 色盘 (HSVPicker)**：2D Hue/Saturation 拾色画布 + 1D 亮度 Bar + Preview 颜色预览。
   - 🔽 **下拉菜单 (Dropdown)**：展开式列表，支持 `SetValues` 动态刷新选项。
   - ✏️ **参数调配输入框 (Input)**：FocusLost 与 Enter 回调，Placeholder 预设文本。
   - ⌨️ **按键绑定 (Keybind)**：自动捕获键盘 KeyCode 按键。
   - 📄 **标签文本 (Label)**：支持主标题与 SubText 说明。
   - 👤 **玩家选择器 (PlayerSelector)**：实时监听 `PlayerAdded` / `PlayerRemoving` 自动同步在线玩家名单。
   - 🖼️ **图片展示 (Image)**：显示图标与描述文本。
   - 🟢 **状态指示灯 (Status)**：显示运行/注入状态。
   - 🔍 **模糊关键字搜索 (CreateSearch)**：顶部集成搜索框，实时模糊匹配过滤当前页面的控件。
   - 🔑 **卡密验证系统 (CreateKeySystem)**：弹出 Modal 验证，内置 setclipboard 获取链接支持。
   - 📊 **FPS & Ping 悬浮窗 (ToggleStats)**：实时监测显示帧率与网络延迟，默认开启，可自由切换。
   - 💧 **悬浮水印挂件 (SetWatermark)**：自定义右顶悬浮面板。
   - 🔔 **通知系统 (Notify)**：Toast 右下角弹窗，开屏自动识别并显示当前注入器名称 (`identifyexecutor`) 与欢迎通知。

4. **✨ 极简视觉与开屏载入**
   - 高级 **Splash Loader** 加载动画面板，配备平滑填满进度条与 Sound 提示音叉。
   - **安全 Clamp 边缘限制**：拖拽窗口时标题栏永远保持在视口边缘之内，避免拉出屏幕外无法拖回。

---

## 🚀 快速快速使用指南 (Quick Start)

### 1. 远程一键加载 (推荐用法)

```lua
-- 通过 GitHub Raw 链接加载最新单文件 UI 库
local LogQuickUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/logz-c/logz-ui-lib/main/script.lua"))()

-- 1. 初始化界面 (开屏载入动画 + 欢迎通知)
LogQuickUI:Initialize({
    Title = "LogQuick 脚本中心",
    Subtitle = "通用 UI 控制面板",
    ScriptAuthor = "Log_quick", -- 脚本作者独立署名
})

-- 2. 设置右上角悬浮水印
LogQuickUI:SetWatermark({ Text = "LogQuick Hub | Log_quick | FPS High" })

-- 3. 创建主功能分区 (Tab)
local mainTab = LogQuickUI:AddTab({ Title = "玩家挂载" })

-- 添加基础属性调节控件
mainTab:AddLabel({ Text = "玩家角色基础属性", SubText = "调整角色 WalkSpeed" })

mainTab:AddSlider({
    Text = "移动速度 (WalkSpeed)",
    Min = 16,
    Max = 250,
    Default = 16,
    Unit = " px",
    Callback = function(v)
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})

mainTab:AddToggle({
    Text = "无敌模式 (GodMode)",
    Default = false,
    Callback = function(state)
        LogQuickUI:Notify({ Title = "功能状态", Text = "无敌状态: " .. tostring(state) })
    end
})

mainTab:AddButton({
    Text = "传送至地图中心",
    Callback = function()
        LogQuickUI:Notify({ Title = "传送结果", Text = "已成功传送至地图中心！" })
    end
})

-- 4. 嵌套功能再分区 (Section -> SubSection)
local targetSec = mainTab:AddSection({ Title = "高级目标控制" })
local targetSubSec = targetSec:AddSubSection({ Title = "玩家目标选择" })

targetSubSec:AddPlayerSelector({
    Text = "选择锁定玩家",
    Callback = function(selectedPlayerName)
        print("当前选择玩家:", selectedPlayerName)
    end
})

targetSubSec:AddKeybind({
    Text = "锁定快捷键",
    Default = Enum.KeyCode.F,
    Callback = function(key)
        LogQuickUI:Notify({ Title = "快捷键设定", Text = "绑定的按键为: " .. key.Name })
    end
})
```

---

## 📄 许可证与作者 (License & Credits)

- **UI 库框架作者**: `Log_quick` (固定不可修改署名)
- **版本**: `v3.0 Master Release`
