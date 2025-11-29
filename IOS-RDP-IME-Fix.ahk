; 脚本名称: iOS RDP 中文输入修复工具 (GUI版)
; 版本: 1.0
; 作者: Akesafe，Gemini 3 Pro
; 项目主页：https://github.com/Akesafe/iOS-RDP-IME-Fix
; 用于修复使用 iOS/iPadOS 微软远程桌面 (RDP) 连接 Windows 时，中文输入法无法唤起的问题，理论上也适用于日文/韩文等使用Windows IME的语言，可兼容部分不需要单独使用Caps Lock、Shift和Ctrl的游戏游戏。
; 原理：iOS上使用微软官方远程桌面客户端Windows App时，使用内置输入法或外接键盘的情况下，对于字符键（例如A-Z/a-z/0-9/!@#$...及空格）按下按键发送给PC端的信息是 `VK_PACKET` (vkE7) Unicode 数据包，而不是物理按键信号；只有功能键（Esc/Tab/Enter/Backspace/F1-F12等）和组合键时发送标准的物理扫描码 (ScanCode)（Ctrl+C/Shift+Enter）会触发，且单独按下 Shift/Ctrl/Caps Lock时通常不发送信号。
; 本软件基于Auto Hotkey，将劫持所有的所有的VK_PACKET（vkE7）数据包，并模拟对应的物理点击；

#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; 1. 全局配置与初始化
; ==============================================================================
InstallKeybdHook
ProcessSetPriority "High"
SendMode "Event"
SetKeyDelay -1, 0

; --- 配置文件路径设置 (保存到 AppData) ---
Global AppConfigDir := A_AppData "\iOS_RDP_Fix"
Global ConfigFile   := AppConfigDir "\Settings.ini"

if !DirExist(AppConfigDir) {
    try {
        DirCreate AppConfigDir
    } catch {
        AppConfigDir := A_Temp "\iOS_RDP_Fix"
        ConfigFile   := AppConfigDir "\Settings.ini"
        DirCreate AppConfigDir
    }
}

; 全局变量
Global ih := ""              
Global IsActive := True      
Global CurrentHotkey := IniRead(ConfigFile, "Settings", "Hotkey", "F8")

; ==============================================================================
; 2. 托盘菜单配置
; ==============================================================================
A_TrayMenu.Delete() ; 清空默认的 AHK 菜单
A_TrayMenu.Add("设置", ShowGui) ; 添加显示界面选项
A_TrayMenu.Add("退出", ExitAppFunc) ; 添加退出选项
A_TrayMenu.Default := "设置" ; 设置默认动作（双击/单击触发）
A_TrayMenu.ClickCount := 1 ; 设置单击图标即可打开界面

; ==============================================================================
; 3. 构建图形界面 (GUI)
; ==============================================================================
MyGui := Gui(, "iOS RDP 中文输入修复工具")

; [关键修改] 点击关闭按钮(X)时，不再退出，而是隐藏窗口
MyGui.OnEvent("Close", (*) => MyGui.Hide()) 

; 添加控件
MyGui.Add("Text", "x20 y20 w200", "当前状态:")
StatusText := MyGui.Add("Text", "x100 y20 w150 cGreen vStatus", "🟢 已启用 (Running)")

MyGui.Add("Text", "x20 y60 w200", "切换开关热键Hot Key:")
HKControl := MyGui.Add("Hotkey", "x20 y85 w120 vChosenHotkey", CurrentHotkey)

BtnApply := MyGui.Add("Button", "x150 y83 w80", "应用")
BtnApply.OnEvent("Click", UpdateHotkey)

MyGui.Add("Text", "x20 y130 w280 h60 cGray", "说明: 程序运行在后台。`n点击右上角[X]会最小化到托盘。`n单击托盘图标可重新显示此窗口。")

MyGui.Add("Link", "x20 y180 w300", '项目主页: <a href="https://github.com/Akesafe/iOS-RDP-IME-Fix">https://github.com/Akesafe/iOS-RDP-IME-Fix</a>')

MyGui.Add("Text", "x20 y210 w300 h20 Right cGray", "Copyright © 2025 Akesafe")


MyGui.Show("w340 h240")

; ==============================================================================
; 4. 核心逻辑初始化
; ==============================================================================
SetupInputHook()

try {
    Hotkey CurrentHotkey, ToggleScript
} catch {
    MsgBox "加载热键 " CurrentHotkey " 失败，请在界面中重新设置。", "错误"
}

; ==============================================================================
; 5. 函数定义
; ==============================================================================

; 显示 GUI 的回调函数
ShowGui(*) {
    MyGui.Show()
    MyGui.Restore() ; 如果之前是最小化状态，将其还原
    WinActivate(MyGui.Hwnd) ; 激活窗口到最前
}

; 真正的退出函数
ExitAppFunc(*) {
    ExitApp()
}

SetupInputHook() {
    Global ih
    ih := InputHook("V")
    ih.KeyOpt("{All}", "I")
    ih.KeyOpt("{vkE7}{sc000}", "-I")
    ih.KeyOpt("{vkE7}{sc000}", "S")
    ih.OnChar := OnPacketChar
    ih.Start()
}

OnPacketChar(ih, char) {
    code := Ord(char)
    if (code < 32)
        return
    if (code == 32) {
        Send "{Blind}{Space}"
        return
    }
    Send "{Blind}{" char "}"
}

ToggleScript(*) {
    Global IsActive
    if (IsActive) {
        ih.Stop()
        StatusText.Value := "🔴 已暂停 (Stopped)"
        StatusText.Opt("cRed")
        IsActive := False
        ToolTip "🔴OFF：RDP修复已暂停"
        SetTimer () => ToolTip(), -2000
    } else {
        ih.Start()
        StatusText.Value := "🟢 已启用 (Running)"
        StatusText.Opt("cGreen")
        IsActive := True
        ToolTip "🟢ON：RDP修复已启用"
        SetTimer () => ToolTip(), -2000
    }
}

UpdateHotkey(*) {
    Global CurrentHotkey
    NewHotkey := HKControl.Value
    
    if (NewHotkey == "") {
        MsgBox "请先设置一个热键！", "提示"
        return
    }
    
    if (NewHotkey == CurrentHotkey)
        return
    
    try {
        if (CurrentHotkey != "")
            Hotkey CurrentHotkey, "Off"
        Hotkey NewHotkey, ToggleScript, "On"
        CurrentHotkey := NewHotkey
        
        try {
            IniWrite(CurrentHotkey, ConfigFile, "Settings", "Hotkey")
            MsgBox "热键已更新并保存为: " NewHotkey, "成功"
        } catch {
            MsgBox "热键生效，但保存配置文件失败。", "警告"
        }
        
    } catch as err {
        MsgBox "热键设置失败: " err.Message, "错误"
        try {
            Hotkey CurrentHotkey, ToggleScript, "On"
        }
    }
}