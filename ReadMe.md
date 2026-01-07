# AHKCommand

**AHKCommand** 是一款基于 **AutoHotkey V2** 构建的高性能、低延迟的生产力工具。
它集成了**文本快速扩展**（Text Expander）与**命令启动器**（Launcher）的功能，专为追求极致效率的开发者、运维人员和文字工作者设计。

核心理念：**零延迟启动、文件即配置、所见即所得。**

---

## ✨ 核心特性

*   **⚡ 极速响应**：基于 `Launcher` 动态编译机制，将所有脚本预加载至内存，呼出窗口无任何IO延迟。
*   **📂 静态文本管理**：通过 `.txt` 文件管理常用语料，支持 Markdown 等任意格式。
*   **🧩 强大的表单系统**：内置 `Form` UI 库，即使不懂复杂的 GUI 编程，也能通过一行代码呼出输入框、下拉菜单、日期选择器。
*   **🛡️ 智能粘贴引擎**：内置 `App.Paste`，自动处理剪贴板备份与恢复，解决中文输入法冲突，确保长文本 100% 完整上屏。
*   **🔍 模糊搜索**：支持空格分隔的多关键字搜索（例如输入 `sql select` 可匹配 `sql_select_query`）。

---

## 📂 目录结构与安装

请确保解压后的文件保持以下结构，**不要随意更改文件夹名称**。

```text
AHKCommand/
├── Launcher.ahk          [启动入口] ★ 双击此处启动程序
├── favicon.ico           [资源文件] 托盘图标与窗口图标
├── Lib/                  [核心库] 
│   ├── Core.ahk          - 核心逻辑、UI 绘制
│   └── Form.ahk          - 表单组件库
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
| **`Alt + 1`** ~ **`9`** | **快速执行** | 直接执行列表中对应序号的命令 |
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
3.  **文件名规则**：`触发词__备注.txt`
    *   **注意**：中间是**两个**下划线 `__`。
    *   `触发词`：你将在搜索框输入的关键字。
    *   `备注`：仅作为文件说明，不会直接显示在列表中，方便你自己管理文件。
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
*注意：描述信息主要用于代码注释，不会直接显示在UI列表中。*

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

## 🎨 交互式表单详解 (Form API)

`Lib/Form.ahk` 提供了极简的 GUI 组件。即使你不懂编程，参照下面的说明也能制作出弹窗。

### 1. 简单输入框 `Form.Input`
用于收集单行文本（如用户名、ID）。

```autohotkey
; 格式: 变量 := Form.Input("窗口标题", "提示语", "默认值")
name := Form.Input("搜索用户", "请输入用户姓名:", "张三")

; 如果用户没取消，name 变量里就是输入的内容
if (name != "")
    App.Paste("查询用户: " name)
```

### 2. 多行文本框 `Form.Textarea`
用于收集大段文本（如提交日志、笔记）。

```autohotkey
; 格式: 变量 := Form.Textarea("窗口标题", "提示语", "默认值", 行数)
note := Form.Textarea("快速笔记", "请粘贴内容:", "", 10)
```

### 3. 下拉菜单 `Form.Select`
让用户从预设列表中选一个。

```autohotkey
; 格式: 变量 := Form.Select("窗口标题", "提示语", ["选项1", "选项2", ...])
env := Form.Select("选择环境", "请选择服务器:", ["测试环境", "生产环境", "预发环境"])
```

### 4. 日期选择器 `Form.Date`
弹出一个日历选择日期。

```autohotkey
; 格式: 变量 := Form.Date("窗口标题", "提示语", "默认日期YYYY-MM-DD")
targetDate := Form.Date("日报", "选择日期:", FormatTime(, "yyyy-MM-dd"))
```

### 5. 确认弹窗 `Form.Confirm`
用于执行前的二次确认，返回 `true` (是) 或 `false` (否)。

```autohotkey
; 格式: if Form.Confirm("标题", "内容")
if Form.Confirm("高危操作", "你确定要删除数据库吗？") {
    MsgBox("已删除！")
}
```

### 6. 万能表单 `Form.Render` (高级) 🔥
一次性弹出一个包含多个输入项的复杂窗口。

**使用方法：**
你需要定义一个列表 `[]`，列表里包含多个对象 `{}`，每个对象代表一行控件。

**支持的控件类型 (Type)：**
*   `Text`: 普通输入框
*   `Select`: 下拉菜单 (需要配合 `Options`)
*   `Date`: 日期选择
*   `Check`: 复选框 (勾选框)

**完整配置示例：**

```autohotkey
MyComplexCommand() {
    ; 1. 定义表单里的字段
    fields := [
        ; 文本框：Name是最后获取结果的关键词，Label是左边的文字
        {Type: "Text",   Label: "服务器IP",  Name: "ip_addr", Default: "192.168.1.1"},
        
        ; 下拉菜单：Options 里放选项列表
        {Type: "Select", Label: "部署环境",  Name: "env",     Options: ["Dev", "Prod", "Test"]},
        
        ; 日期选择
        {Type: "Date",   Label: "执行日期",  Name: "run_date"},
        
        ; 复选框：Default: 1 表示默认勾选，0 表示默认不勾选
        {Type: "Check",  Label: "强制重启",  Name: "is_force", Default: 0}
    ]
    
    ; 2. 显示表单，结果存入 data 变量
    data := Form.Render("生成部署命令", fields)
    
    ; 3. 如果 data 为空，说明用户点了取消或关闭了窗口
    if (data == "") 
        return

    ; 4. 使用 data["Name"] 来获取对应的值
    ; 注意：复选框(Check)返回 1(勾选) 或 0(未勾选)
    cmd := "deploy tool --ip=" data["ip_addr"] " --env=" data["env"]
    
    if (data["is_force"] == 1)
        cmd .= " --force"
        
    App.Paste(cmd)
}

; 注册这个命令
App.Register("deploy", MyComplexCommand, "生成部署脚本")
```

---

## 🛠️ 外观配置

如需修改字体、颜色、窗口大小，请编辑 `Lib/Core.ahk` 文件顶部的 `Settings` 对象：

```autohotkey
static Settings := {
    ColorWinBg:       "FFFFFF",   ; 背景色 (十六进制)
    Width:            480,        ; 窗口宽度
    ListRows:         14,         ; 列表显示行数
    FontSizeInput:    14,         ; 搜索框字号
    FontSizeList:     10,         ; 列表字号
    FontWeightList:   "700",      ; 列表字体粗细 (400正常, 700粗体)
}
```
修改配置后，请按 **`Alt + F12`** 重启生效。