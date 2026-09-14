# 银狼智能交互精灵 - iOS版

> 《崩坏：星穹铁道》银狼人设 AI 智能助手，融合对话、音乐、智能家居于一体。

## 功能特性

### 🎭 银狼人设对话
- 系统提示词锁定黑客少女人设（毒舌、慵懒、傲娇）
- 黑客黑话自动替换（"搞定"→"调试完成"，"不行"→"权限不足"）
- 口头禅自动追加（嘛/而已/罢了/敲键盘声）
- 每次对话自动称呼用户"小黎"
- 对话历史本地持久化（SwiftData）

### 🎵 网易云音乐
- 在线搜索播放（网易云API）
- 底部播放栏 + 全屏播放器（封面旋转动画）
- 链路收藏（本地加密存储）
- 智能分类（战斗/探索/休憩/叙事链路）
- 语音指令控制（"播放音乐"/"下一首"/"收藏"）

### 🏠 智能家居
- 红外设备控制（灯/空调/电视/风扇）
- 场景模式（离家/观影/睡眠）
- 空调温度调节

### ⚙️ 系统设置
- 网络链路管理（WiFi/4G/蓝牙）
- 声纹解锁（小黎专属）
- 云同步配置
- AI大模型API配置

### 🎙️ 语音交互
- 语音输入（预留接口）
- 音乐指令语音解析
- 声纹识别（预留接口）

## 技术栈

| 模块 | 技术 |
|------|------|
| UI框架 | SwiftUI + iOS 16.0+ |
| 状态管理 | ObservableObject + EnvironmentObject |
| 本地存储 | SwiftData |
| 音频播放 | AVPlayer |
| 网络请求 | URLSession + async/await |
| AI对话 | 大模型API（可切换） |
| 音乐源 | 网易云音乐API |

## 项目结构

```
SilverWolf/
├── SilverWolfApp.swift          # App入口 + 底部Tab导航
├── AppState.swift               # 全局状态管理
├── Info.plist                   # 配置文件（权限/API Key）
├── Features/
│   ├── Chat/                    # 银狼对话模块
│   │   ├── ChatView.swift       # 对话界面
│   │   ├── ChatViewModel.swift  # 对话逻辑 + 音乐指令解析
│   │   └── SilverWolfPersona.swift  # 银狼人设规则
│   ├── Music/                   # 网易云音乐模块
│   │   ├── MusicView.swift      # 音乐主界面（搜索/收藏/分类）
│   │   ├── MusicViewModel.swift # 播放控制 + 收藏管理
│   │   ├── PlayerBar.swift      # 底部播放栏 + 全屏播放器
│   │   └── NetEaseService.swift # 网易云API封装
│   ├── SmartHome/               # 智能家居模块
│   │   └── SmartHomeView.swift  # 设备控制 + 场景模式
│   ├── Settings/                # 设置模块
│   │   └── SettingsView.swift   # 系统设置 + 声纹录入
│   └── Voice/                   # 语音模块（待实现）
├── Models/
│   ├── ChatMessage.swift        # 对话消息模型
│   └── Song.swift               # 歌曲/歌单模型
└── Services/
    └── AIService.swift          # AI大模型API服务
```

## 快速开始

### 1. 环境要求
- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+

### 2. 配置API Key
打开 `Info.plist`，替换以下配置：

```xml
<key>AI_API_KEY</key>
<string>你的大模型API密钥</string>
<key>AI_BASE_URL</key>
<string>https://api.openai.com/v1/chat/completions</string>
<key>AI_MODEL</key>
<string>gpt-3.5-turbo</string>
```

> 支持兼容 OpenAI 格式的所有大模型服务（如 DeepSeek、通义千问、智谱等），只需修改 `AI_BASE_URL` 和 `AI_MODEL`。

### 3. 运行
1. 用 Xcode 打开项目
2. 选择 iOS 模拟器或真机
3. 按 `Cmd + R` 运行

## 银狼人设说明

### 核心规则
- **身份**：星际顶级黑客，擅长代码和网络攻防
- **性格**：冷静毒舌、慵懒随性、略带傲娇
- **语言**：黑客黑话 + 口头禅（嘛/而已/罢了）
- **称呼**：每次对话叫用户"小黎"

### 示例对话
| 用户输入 | 银狼回复 |
|---------|---------|
| 你好 | 小黎，啧，有事直说，我可没闲工夫寒暄而已 |
| 播放音乐 | 小黎，已启动音频播放进程，正在建立传输链路嘛 |
| 我好生气 | 小黎，啧，情绪模块出bug了？格式化一下试试罢了 |
| 下一首 | 小黎，已切换至下一条音频链路（敲键盘声） |

## 语音指令列表

在对话页直接说/输入以下指令即可控制音乐：

| 指令 | 功能 |
|------|------|
| 播放音乐 / 放歌 | 播放/继续 |
| 播放XXX | 搜索并播放指定歌曲 |
| 暂停 / 停一下 | 暂停播放 |
| 下一首 / 换一首 | 切换下一曲 |
| 上一首 | 切换上一曲 |
| 收藏 / 加入歌单 | 收藏当前歌曲 |
| 音量大 / 调大 | 音量+10% |
| 音量小 / 调小 | 音量-10% |

## 待实现功能

- [ ] 语音ASR实时识别（Speech框架）
- [ ] TTS银狼音色合成
- [ ] 声纹识别（MFCC+GMM）
- [ ] 云同步（Supabase/自建后端）
- [ ] 红外发射（通过网关）
- [ ] 蓝牙设备控制
- [ ] 4G网络状态监控
- [ ] 歌词显示
- [ ] 歌单管理

## 许可证

MIT License
