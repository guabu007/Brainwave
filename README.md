# Brainwave - 闪念胶囊

一个基于 Whisper 模型的语音转写 iOS App，支持中英文混合识别，自动保存到 Obsidian。

## 功能特性

- ✅ **语音录音** - 使用 AVFoundation 进行高质量录音
- ✅ **Whisper 转写** - 基于 OpenAI Whisper 模型，支持中英文混合识别
- ✅ **Obsidian 集成** - 自动保存转写结果到 Obsidian 格式笔记
- ✅ **Action Button 支持** - 一键快速启动录音
- ✅ **波形可视化** - 实时显示录音波形

## 技术栈

- **iOS**: Swift 5, UIKit, AVFoundation
- **语音转写**: OpenAI Whisper (base model)
- **后端**: Python, FastAPI
- **笔记存储**: Obsidian 兼容格式

## 快速开始

### 1. 设置后端服务

```bash
cd server
pip install -r requirements.txt
python whisper_server.py
```

服务将在 http://localhost:8000 启动。

### 2. 运行 iOS App

使用 Xcode 打开 `Brainwave.xcodeproj`，选择目标设备或模拟器，点击运行。

### 3. 配置 Action Button (iOS 17+)

1. 打开 iPhone 设置
2. 进入「辅助功能」>「动作按钮」
3. 选择「打开 App」> 选择 Brainwave

## 使用流程

1. **按下 Action Button** → App 自动启动并开始录音
2. **说话** → 实时显示波形
3. **点击停止** → 发送音频到 Whisper 服务
4. **识别完成** → 显示转写文本，可编辑
5. **保存** → 自动保存到 Obsidian 格式笔记

## 项目结构

```
Brainwave/
├── Brainwave.xcodeproj/      # Xcode 项目配置
├── Brainwave/                # iOS App 源代码
│   ├── AppDelegate.swift     # 应用入口，处理快捷操作
│   ├── SceneDelegate.swift   # 场景管理
│   ├── ViewController.swift  # 主界面，显示笔记列表
│   ├── Services/             # 服务层
│   │   ├── AudioRecorder.swift      # 音频录音服务
│   │   ├── WhisperTranscriber.swift # Whisper 转写服务
│   │   └── ObsidianManager.swift    # Obsidian 笔记管理
│   └── ViewControllers/
│       └── RecordingViewController.swift  # 录音界面
└── server/                   # Whisper 后端服务
    ├── whisper_server.py     # FastAPI 服务
    └── requirements.txt      # Python 依赖
```

## 注意事项

1. 确保后端服务运行在 http://localhost:8000
2. 首次使用需要下载 Whisper 模型（约 1.5GB）
3. 需要麦克风权限
4. 建议使用真机测试，模拟器可能存在音频问题

## License

MIT
