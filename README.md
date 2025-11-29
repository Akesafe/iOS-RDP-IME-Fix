# iRDP Input Fixer

<img width="342" height="270" alt="image" src="https://github.com/user-attachments/assets/7facf134-c728-419f-9179-3755b2580264" />

用于修复在 iOS/iPadOS 上使用微软官方远程桌面客户端（Windows App）连接 Windows 时，PC端的中文输入法（IME）无法唤起的问题。理论上也适用于日文、韩文等使用 Windows IME 框架的语言，并可兼容部分不需要单独使用 Caps Lock、Shift 和 Ctrl 的游戏。

### 🔧 原理

iOS 上的微软远程桌面客户端，配合内置输入法或外接键盘时：

*   **字符键：**  `A-Z/a-z/0-9/!@#$...`及空格，按下按键时发送给 PC 端的信息是 VK_PACKET(vkE7) Unicode 数据包，而不是物理按键信号；
*   **功能键与组合键：** `Esc`、`Tab`、`Enter`、`Backspace`、`F1-F12` 等，以及 `Ctrl+C`、`Shift+Enter`按下时会发送标准的物理扫描码（ScanCode）；
*   **修饰键：** 单独按下 `Shift`、`Ctrl` 或 `Caps Lock` 时，客户端不发送信号。

### 🛠️ 修复机制

本软件基于 AutoHotkey 开发，将劫持所有的所有的VK_PACKET（vkE7）数据包，并模拟对应的物理点击；

### ⚠️ 已知限制

单独按下Shift或Ctrl没有反应，这是iOS客户端的限制，此问题无解，建议使用F8（或其他自定义功能键）代替。



By *Akesafe.*
