# 🎙️ Murmur

<p align="center">
<a href="../README.md"><img src="https://hatscripts.github.io/circle-flags/flags/gb.svg" width="24"></a>&nbsp;
<a href="README_RU.md"><img src="https://hatscripts.github.io/circle-flags/flags/ru.svg" width="24"></a>&nbsp;
<a href="README_ES.md"><img src="https://hatscripts.github.io/circle-flags/flags/es.svg" width="24"></a>&nbsp;
<a href="README_HI.md"><img src="https://hatscripts.github.io/circle-flags/flags/in.svg" width="24"></a>&nbsp;
<a href="README_AR.md"><img src="https://hatscripts.github.io/circle-flags/flags/sa.svg" width="24"></a>&nbsp;
<a href="README_FR.md"><img src="https://hatscripts.github.io/circle-flags/flags/fr.svg" width="24"></a>&nbsp;
<a href="README_BN.md"><img src="https://hatscripts.github.io/circle-flags/flags/bd.svg" width="24"></a>&nbsp;
<a href="README_PT.md"><img src="https://hatscripts.github.io/circle-flags/flags/br.svg" width="24"></a>&nbsp;
<a href="README_UR.md"><img src="https://hatscripts.github.io/circle-flags/flags/pk.svg" width="24"></a>
</p>

**语音转意义，而非语音转文字。**

用你的母语说话，获得任意语言的文本。

一款 macOS 菜单栏工具，捕捉你的语音，输出干净自然的目标语言文本。不是逐字翻译。Murmur 理解你的意思，然后用母语者的方式把它写出来。

## 😤 痛点

用非母语写作很慢。你要么：

- 先用母语写好，粘贴到翻译工具里，再修改别扭的翻译结果
- 直接用目标语言写，每个词都拿不准，反复查词，反复检查读起来是否自然
- 用 AI 翻译，然后花时间修改，因为输出太生硬或语气不对

当你和 AI 智能体协作时，这个问题更加突出。英语是更好的选择（token 更少，模型理解力更强），但思考却是用母语进行的。

## 💡 解决方案

按下快捷键，说出你的想法，立刻得到目标语言的成品文本。

```
Option+Space  →  用任意语言说话  →  Option+Space
                                         ↓
                              文本出现在你的光标位置
```

Murmur 不会逐字翻译。它接收你的口语表达，去掉口头禅和语气词，生成符合目标语言语法、语气和表达习惯的文本。最终结果读起来像直接写的，而不是翻译的。

## ⚙️ 工作原理

1. **按下快捷键**（默认 `Option + Space`），录音指示器出现。
2. **开始说话**，用任意语言，想到什么说什么。
3. **点击**任意文本输入框（浏览器、编辑器、聊天工具、终端）。
4. **再次按下快捷键**，文本出现在你需要的位置。

无需切换应用，无需复制粘贴，无需手动修改。

## 🔀 三种模式

- **转录模式**：原始语音转文字，保留原始语言。
- **整理模式**：语言不变，但文本经过整理。去掉口头禅，修正语法，结构化句子。列举内容自动格式化为列表。
- **翻译模式**：用一种语言说话，得到另一种语言的整洁文本。支持 97 种语言。同样经过整理：输出读起来像母语者写的，而不是翻译过来的。

## 📦 安装

从 [Releases](https://github.com/alexe-ev/Murmur/releases) 下载 `Murmur.dmg`，拖入"应用程序"文件夹即可。

> 未经公证。首次启动时：右键点击应用，选择"打开"。

### 从源码构建

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

### 初始设置

首次启动时，需授予**麦克风**和**辅助功能**权限。在"设置"中输入你的 [OpenAI API key](https://platform.openai.com/api-keys)。

## 📋 系统要求

- macOS 13.0+（Ventura 或更高版本）
- Apple Silicon（M1/M2/M3/M4）
- OpenAI API key

录音文件为临时文件，转录完成后立即删除。API key 仅存储在本地设备上。

## 📄 许可证

[MIT](../LICENSE)
