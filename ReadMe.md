# AHKCommand

**AHKCommand** 是一款基于 **AutoHotkey V2** 构建的高性能、低延迟的生产力工具。
它集成了**文本快速扩展**（Text Expander）与**命令启动器**（Launcher）的功能，专为追求极致效率的开发者、运维人员和文字工作者设计。

核心理念：**零延迟启动、文件即配置、所见即所得。**

---

## ✨ 核心特性

*   **⚡ 极速响应**：基于 `Launcher` 动态编译机制，将所有脚本预加载至内存，呼出窗口无任何IO延迟。
*   **📂 静态文本管理**：通过 `.txt` 文件管理常用语料（Prompt/代码段/邮件模板），**无需转义**，支持 Markdown 等任意格式。
*   **🧩 强大的表单系统**：内置 `Form` UI 库，一行代码即可呼出输入框、下拉菜单、日期选择器，轻松实现参数化命令（如生成带变量的 SQL/Shell 命令）。
*   **🛡️ 智能粘贴引擎**：内置 `App.Paste`，自动处理剪贴板备份与恢复，解决中文输入法冲突，确保长文本 100% 完整上屏。
*   **🔍 模糊搜索**：支持空格分隔的多关键字搜索（例如输入 `sql select` 可匹配 `sql_select_query`）。

---

## 📂 目录结构与安装

请确保解压后的文件保持以下结构，**不要随意更改文件夹名称**，否则程序无法运行。

```text
AHKCommand/
├── Launcher.ahk          [启动入口] ★ 双击此处启动程序
├── favicon.ico           [资源文件] 托盘图标与窗口图标
├── Lib/                  [核心库] 
│   ├── Core.ahk          - 核心逻辑、UI 绘制、配置项
│   └── Form.ahk          - 表单组件库 (Input, Select, Date, Render...)
├── Commands/             [脚本扩展] 存放 .ahk 文件
│   └── myCommands.ahk    - 你的自定义脚本功能
└── Texts/                [文本扩展] 存放 .txt 文件
    ├── work/             - 支持子文件夹归类
    │   └── sql__查询用户.txt
    └── personal/
        └── address.txt
```

---

## 🚀 快速上手

### 1. 启动程序
双击根目录下的 **`Launcher.ahk`**。
> *注意：程序启动后会隐身运行，仅在任务栏托盘显示图标。*

### 2. 常用快捷键

| 快捷键 | 作用 | 备注 |
| :--- | :--- | :--- |
| **`Alt + Space`** | **呼出/隐藏 主窗口** | 全局热键 |
| **`Ctrl + Enter`** | **执行选中的命令** | 防止误触，区别于普通回车 |
| **`Alt + 1`** ~ **`9`** | **快速执行** | 执行列表中的第 1-9 项 |
| `Up` / `Down` | 切换选中项 | 支持 `Tab` / `Shift+Tab` |
| `Left` | 一键清空搜索框 | |
| **`Alt + F12`** | **重启/重载程序** | 修改文件后必须执行此操作 |

> **提示**：为什么是 `Ctrl + Enter`？
> 为了避免在输入中文搜索词时，按下回车选词导致意外触发命令。

---

## 📖 文本扩展指南 (Texts 文件夹)

这是最简单的扩展方式，适合存储**静态长文本**。

1.  进入 `Texts` 文件夹（支持创建子文件夹）。
2.  新建 `.txt` 文件。
3.  **文件名规则**：`触发词__描述.txt`
    *   **注意**：中间是**两个**下划线 `__`。
    *   `触发词`：用于搜索的关键字。
    *   `描述`：显示在列表右侧的辅助说明。
4.  **文件内容**：放入你想要粘贴的任何文本（推荐使用 **UTF-8** 编码防止乱码）。

**示例：**
*   文件：`Texts\addr__家庭地址.txt`
*   内容：`浙江省杭州市西湖区...`
*   **效果**：呼出窗口搜索 `addr`，按下 `Ctrl+Enter` 即可粘贴地址。

---

## ⚡ 脚本扩展指南 (Commands 文件夹)

适合需要**动态计算**、**交互输入**或**系统操作**的场景。
在 `Commands` 文件夹下新建任意 `.ahk` 文件即可，程序会自动加载。

### 1. 注册命令 API
```autohotkey
App.Register(触发词, 处理逻辑, 描述)
```

**基础示例：**
```autohotkey
; 1. 静态文本替换
App.Register("mail", "myname@example.com", "我的邮箱")

; 2. 运行计算器 (使用 Lambda 函数)
App.Register("calc", (*) => Run("calc.exe"), "启动计算器")

; 3. 动态获取时间
App.Register("now", (*) => App.Paste(FormatTime(, "yyyy-MM-dd HH:mm")), "当前时间")
```

### 2. 核心粘贴函数 `App.Paste(text)`
**强烈建议**使用此函数代替原生的 `Send`。它包含以下保护机制：
1.  备份当前剪贴板。
2.  将文本写入剪贴板。
3.  发送 `Ctrl+V`。
4.  恢复原有剪贴板内容。

---

## 🎨 交互式表单 (Form API)

`Lib/Form.ahk` 提供了极简的 GUI 组件，让你的脚本具备交互能力。

### 1. 简单输入框 (Input / Textarea)
```autohotkey
; Form.Input(标题, 提示语, 默认值)
name := Form.Input("搜索", "请输入查询内容:", "默认值")

; Form.Textarea(标题, 提示语, 默认值, 行数)
note := Form.Textarea("笔记", "请输入多行内容:", "", 10)
```

### 2. 选择器 (Select / Date)
```autohotkey
; Form.Select(标题, 提示语, 选项数组)
color := Form.Select("选择颜色", "请选择:", ["红色", "绿色", "蓝色"])

; Form.Date(标题, 提示语, 默认日期YYYY-MM-DD)
date := Form.Date("日报", "选择日期:", FormatTime(, "yyyy-MM-dd"))
```

### 3. 确认框 (Confirm)
```autohotkey
if Form.Confirm("危险操作", "确定要删除吗？") {
    MsgBox("已删除")
}
```

### 4. 万能表单 (Form.Render) 🔥
一次性收集多个参数，非常适合生成复杂的命令行语句或模板。

**参数定义：**
*   `Type`: 控件类型 (`Text`, `Select`, `Date`, `Check`)
*   `Label`: 左侧标签文字
*   `Name`: 对应结果 Map 中的 Key
*   `Default`: 默认值 (Select类型为索引或文字，Check类型为0/1)
*   `Options`: 下拉菜单的选项数组 (仅 Select 类型有效)

**完整示例：**
```autohotkey
MyComplexCommand() {
    ; 1. 定义字段结构
    fields := [
        {Type: "Text",   Label: "服务器地址", Name: "host",    Default: "192.168.1.1"},
        {Type: "Select", Label: "环境",       Name: "env",     Options: ["Dev", "Prod"]},
        {Type: "Date",   Label: "部署日期",   Name: "date"},
        {Type: "Check",  Label: "强制重启",   Name: "force",   Default: 0}
    ]
    
    ; 2. 渲染表单，返回 Map 对象
    data := Form.Render("生成部署命令", fields)
    
    ; 3. 处理取消情况 (data 为空)
    if (data == "") 
        return

    ; 4. 生成结果
    cmd := "deploy --host=" data["host"] " --env=" data["env"] " --date=" data["date"]
    if (data["force"])
        cmd .= " --force"
        
    App.Paste(cmd)
}
App.Register("deploy", MyComplexCommand, "生成部署脚本")
```

---

## 🛠️ 配置说明

如需修改外观（字体、颜色、宽度），请编辑 `Lib/Core.ahk` 文件顶部的 `Settings` 对象：

```autohotkey
static Settings := {
    ColorWinBg:       "FFFFFF",   ; 背景色
    Width:            480,        ; 窗口宽度
    ListRows:         14,         ; 列表显示行数
    FontSizeInput:    14,         ; 搜索框字号
    FontSizeList:     10,         ; 列表字号 (建议保持 10-12)
    FontWeightList:   "700",      ; 列表字体粗细 (700为粗体)
    ; ...
}
```

修改配置后，请按 **`Alt + F12`** 重启生效。

---

## ❓ 常见问题 (FAQ)

**Q: 为什么我添加了文件/修改了代码，搜索不到？**
A: AHKCommand 采用预编译机制。任何文件变动（添加 .txt 或修改 .ahk），都必须**重启程序**才能生效。
*   快捷键：`Alt + F12`
*   或：右键托盘图标 -> 重启程序 (Reload)。

**Q: 搜索框无法输入中文？**
A: 程序完全支持中文。如果无法输入，请检查是否被某些输入法（如旧版微软拼音）拦截，尝试切换输入法或重启程序。

**Q: 粘贴长文本时出现乱码？**
A: 请务必确保 `Texts` 目录下的 `.txt` 文件保存为 **UTF-8** 编码。

**Q: 按 Ctrl+Enter 没有反应？**
A: 请确保目标窗口（如记事本、VSCode）处于激活状态。`App.Paste` 会尝试激活上一个窗口，如果失败则无法粘贴。