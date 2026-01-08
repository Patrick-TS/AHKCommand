; Lib/Core.ahk
; V3.2: Refined Fonts, Fixed Truncation, Optimized Layout
#Requires AutoHotkey v2.0

class App {
    static Settings := {
        ColorWinBg:       "FFFFFF",   
        ColorSearchBorder:"E0E0E0",   
        
        ; --- 1. 尺寸定义 (保持窄长) ---
        Width:            480,        ; 宽度
        ListRows:         14,         ; 行数
        HeightRow:        40,         ; 行高
        
        ; --- 2. 顶部布局 ---
        IconSize:         36,         ; [微调] 图标稍微改小一点点，更精致
        HeightInput:      36,         ; [微调] 输入框高度跟随
        FontSizeInput:    14,         ; [修改] 输入字号稍微减小，更秀气
        
        ; --- 3. 列表字体 (关键修改) ---
        FontSizeList:     10,         ; [修改] 字号减小，配合粗体更耐看
        FontWeightList:   "700",      ; 保持粗体
        
        IconFile:         "favicon.ico"
    }

    static Commands := []
    static GuiObj := ""
    static HListView := ""
    static HSearch := ""
    static Visible := false
    static LastActiveWindow := 0 
    static SelectedRow := 1 
    static RootDir := "" 
    static ImageListID := ""
    static CurrentFilteredList := [] 
    
    static Init(rootDir := "") {
        this.RootDir := rootDir
        this.SetupTray() 
        this.BuildGui()
        this.RegisterHotkeys()
    }

    static SetupTray() {
        A_IconTip := "AHKCommand"
        if (this.RootDir != "" && FileExist(this.RootDir "\favicon.ico")) {
            try {
                TraySetIcon(this.RootDir "\favicon.ico")
            }
        }
        A_TrayMenu.Delete() 
        A_TrayMenu.Add("重启程序 (Reload)", (*) => this.ReloadApp())
        A_TrayMenu.Add("退出程序 (Exit)", (*) => this.ExitClean())
        A_TrayMenu.Default := "重启程序 (Reload)" 
    }

    ; [修复] 防止窗口闪烁
    static ReloadApp() {
        this.Visible := false
        if (this.GuiObj) {
            this.GuiObj.Hide()
            this.GuiObj.Destroy()
            this.GuiObj := ""
        }
            
        launcherPath := this.RootDir "\Launcher.ahk"
        if FileExist(launcherPath) {
            Run("`"" A_AhkPath "`" `"" launcherPath "`"", , "Hide")
            ExitApp 
        } else {
            MsgBox("Error: Launcher.ahk not found!")
        }
    }

    ; [修复] 防止窗口闪烁
    static ExitClean() {
        this.Visible := false
        if (this.GuiObj) {
            this.GuiObj.Hide()
            this.GuiObj.Destroy()
            this.GuiObj := ""
        }
        ExitApp()
    }

    static RegisterHotkeys() {
        Hotkey("!F12", (*) => this.ReloadApp()) 
        Hotkey("!Space", (*) => this.Toggle())
        
        HotIf (*) => this.Visible && WinActive("ahk_id " this.GuiObj.Hwnd)
        Hotkey("Tab", (*) => this.Navigate("Down"))
        Hotkey("+Tab", (*) => this.Navigate("Up"))
        Hotkey("Up", (*) => this.Navigate("Up"))
        Hotkey("Down", (*) => this.Navigate("Down"))
        Hotkey("^Enter", (*) => this.ExecuteSelection())
        Hotkey("^NumpadEnter", (*) => this.ExecuteSelection())
        Hotkey("Left", (*) => this.QuickClear())
        
        Loop 9 {
            k := A_Index
            Hotkey("!" k, ((idx, *) => this.ExecuteByIndex(idx)).Bind(k))
        }
        HotIf
    }
    
    static LoadText(filepath, trigger, desc) {
        try {
            if FileExist(filepath)
                this.Register(trigger, FileRead(filepath, "UTF-8"), desc)
        }
    }

    static Register(trigger, handler, desc := "") {
        this.Commands.Push({Trigger: trigger, Handler: handler, Desc: desc})
    }

    static Paste(text) {
        ClipboardHistory := ClipboardAll()
        A_Clipboard := ""
        A_Clipboard := text
        
        if !ClipWait(1, 0)
            return 

        if (this.LastActiveWindow && WinExist("ahk_id " this.LastActiveWindow)) {
            WinActivate("ahk_id " this.LastActiveWindow)
            if !WinWaitActive("ahk_id " this.LastActiveWindow, , 2)
                return
        }
        
        SendInput("^v")
        Sleep(150)
        A_Clipboard := ClipboardHistory
        ClipboardHistory := ""
    }

    static BuildGui() {
        S := this.Settings 

        this.GuiObj := Gui("-Caption +ToolWindow +AlwaysOnTop +Owner +Border +E0x02000000", "AHKCommand")
        this.GuiObj.BackColor := S.ColorWinBg
        this.GuiObj.MarginX := 12
        this.GuiObj.MarginY := 12
        this.GuiObj.SetFont("s" S.FontSizeInput, "Segoe UI")
        
        ; 1. 图标
        iconFile := (this.RootDir != "" && FileExist(this.RootDir "\" S.IconFile)) ? (this.RootDir "\" S.IconFile) : A_AhkPath
        this.GuiObj.Add("Picture", "x12 y12 w" S.IconSize " h" S.IconSize, iconFile)

        ; 2. 搜索框
        searchW := S.Width - 24 - S.IconSize - 12
        this.HSearch := this.GuiObj.Add("Edit", "x+12 y12 w" searchW " h" S.HeightInput " +Border vSearchBox")
        this.HSearch.OnEvent("Change", (*) => this.OnSearch())

        ; 3. 列表
        this.GuiObj.SetFont("s" S.FontSizeList " w" S.FontWeightList, "Segoe UI")
        listY := 12 + S.HeightInput + 12
        
        this.HListView := this.GuiObj.Add("ListView", "x0 y" listY " w" S.Width " r" S.ListRows " -Hdr -Multi -E0x200 +LV0x10020 BackgroundFFFFFF", ["Trigger", "Shortcut"])
        
        ; 撑开行高
        this.ImageListID := IL_Create(1, 1, 0)
        DllCall("ImageList_SetIconSize", "Ptr", this.ImageListID, "Int", 1, "Int", S.HeightRow)
        this.HListView.SetImageList(this.ImageListID, 1)
        
        DllCall("uxtheme\SetWindowTheme", "Ptr", this.HListView.Hwnd, "Str", "Explorer", "Str", "")
        
        ; 4. 列宽与对齐 (修复截断)
        scrollBarWidth := 25
        colShortcutW := 80
        colTriggerW  := S.Width - colShortcutW - scrollBarWidth
        
        this.HListView.ModifyCol(1, "Left " colTriggerW) 
        this.HListView.ModifyCol(2, "Right " colShortcutW) 

        this.GuiObj.OnEvent("Escape", (*) => this.Hide())
        this.GuiObj.OnEvent("Close", (*) => this.Hide())
        OnMessage(0x0006, (wParam, lParam, msg, hwnd) => this.CheckActive(wParam, lParam, msg, hwnd))
        ; 修复：ListView的Click事件会传递行号参数
        this.HListView.OnEvent("Click", (ctrl, row, *) => this.OnListViewClick(row))
    }

    static Navigate(direction) {
        count := this.HListView.GetCount()
        if (count = 0)
            return

        nextRow := this.SelectedRow
        if (direction = "Down")
            nextRow++
        else
            nextRow--

        if (nextRow > count)
            nextRow := 1
        if (nextRow < 1)
            nextRow := count
            
        this.SelectedRow := nextRow
        this.HListView.Modify(0, "-Select -Focus") 
        this.HListView.Modify(this.SelectedRow, "Select Focus Vis") 
    }

    static OnSearch() {
        this.UpdateList(this.HSearch.Value)
    }

    static UpdateList(query := "") {
        this.HListView.Opt("-Redraw") 
        this.HListView.Delete()
        this.CurrentFilteredList := []
        
        query := StrLower(Trim(query))
        keywords := (query == "") ? [] : StrSplit(query, " ")
        
        idx := 0
        for cmd in this.Commands {
            isMatch := true
            searchSource := StrLower(cmd.Trigger)
            
            for kw in keywords {
                if (kw != "" && !InStr(searchSource, kw)) {
                    isMatch := false
                    break 
                }
            }
            
            if (isMatch) {
                idx++
                this.CurrentFilteredList.Push(cmd)
                shortcutText := (idx <= 9) ? "Alt+" idx : ""
                this.HListView.Add("", cmd.Trigger, shortcutText)
            }
        }
        
        if (this.HListView.GetCount() > 0) {
            this.SelectedRow := 1 
            this.HListView.Modify(1, "Select Vis")
        } else {
            this.SelectedRow := 0
        }
        this.HListView.Opt("+Redraw")
    }
    
    static ExecuteByIndex(index) {
        if (index > this.CurrentFilteredList.Length)
            return
        this.SelectedRow := index
        this.ExecuteSelection()
    }

    static Toggle() {
        if this.Visible
            this.Hide()
        else
            this.Show()
    }

    static Show() {
        this.LastActiveWindow := WinExist("A")
        this.Visible := true
        this.HSearch.Value := ""
        this.UpdateList()
        this.GuiObj.Show("AutoSize Center Hide")
        DllCall("AnimateWindow", "Ptr", this.GuiObj.Hwnd, "Int", 100, "Int", 0xA0000)
        try {
            WinActivate("ahk_id " this.GuiObj.Hwnd)
            this.HSearch.Focus()
        }
    }

    static Hide() {
        if !this.Visible
            return
        this.Visible := false
        try {
            DllCall("AnimateWindow", "Ptr", this.GuiObj.Hwnd, "Int", 100, "Int", 0x90000) 
            this.GuiObj.Hide()
        }
    }

    static OnListViewClick(row) {
        if (row > 0 && row <= this.CurrentFilteredList.Length) {
            this.SelectedRow := row
            this.ExecuteSelection()
        }
    }

    static ExecuteSelection() {
        if (this.SelectedRow = 0 || this.SelectedRow > this.CurrentFilteredList.Length) {
            ; 如果没有有效的选中行，尝试获取焦点行（键盘导航时使用）
            focusedRow := this.HListView.GetNext(0, "Focused")
            if (focusedRow > 0 && focusedRow <= this.CurrentFilteredList.Length) {
                this.SelectedRow := focusedRow
            } else {
                return
            }
        }
        targetCmd := this.CurrentFilteredList[this.SelectedRow]
        this.Hide()
        
        if (Type(targetCmd.Handler) = "String") {
            this.Paste(targetCmd.Handler)
        } else if (HasMethod(targetCmd.Handler)) {
            targetCmd.Handler.Call()
        }
    }
    
    static CheckActive(wParam, lParam, msg, hwnd) {
        if (this.GuiObj && hwnd == this.GuiObj.Hwnd && wParam == 0 && this.Visible) {
            SetTimer(() => this.Hide(), -10)
        }
    }

    static QuickClear() {
        if (this.HSearch.Value != "") {
            this.HSearch.Value := ""
            this.UpdateList()
        }
    }
}