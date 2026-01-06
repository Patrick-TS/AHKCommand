; Lib/Form.ahk
; A styled, easy-to-use form builder for AHKCommand.
; Includes: Input, Select, Textarea, Date, Confirm, and Render (Complex Form).
#Requires AutoHotkey v2.0

class Form {
    ; --- UI Style Configuration ---
    static Style := {
        FontName: "Segoe UI",
        FontSize: 11,
        ColorBg:  "FFFFFF",   ; Window Background
        ColorTxt: "333333",   ; Text Color
        ColorBtn: "F0F0F0"    ; Button Background
    }

    ; =================================================================
    ; 1. Simple Input (单行输入)
    ; usage: name := Form.Input("Title", "Please enter name:", "Default")
    ; =================================================================
    static Input(title, prompt, defaultVal := "") {
        Result := ""
        g := this.CreateBaseGui(title)
        g.Add("Text", "w350 c666666", prompt)
        g.Add("Edit", "y+8 w350 h32 -E0x200 +Border vValue", defaultVal)
        this.AddButtons(g, (*) => (Result := g["Value"].Value, g.Destroy()))
        g.Show()
        WinWaitClose("ahk_id " g.Hwnd)
        return Result
    }

    ; =================================================================
    ; 2. Textarea (多行文本域)
    ; usage: text := Form.Textarea("Commit Msg", "Details:", "", 10)
    ; =================================================================
    static Textarea(title, prompt, defaultVal := "", rows := 8) {
        Result := ""
        g := this.CreateBaseGui(title)
        g.Add("Text", "w400 c666666", prompt)
        ; +Multi: Multi-line, +WantTab: Allow Tab key
        g.Add("Edit", "y+8 w400 r" rows " -E0x200 +Border +Multi +WantTab vValue", defaultVal)
        this.AddButtons(g, (*) => (Result := g["Value"].Value, g.Destroy()))
        g.Show()
        WinWaitClose("ahk_id " g.Hwnd)
        return Result
    }

    ; =================================================================
    ; 3. Select (下拉选择)
    ; usage: item := Form.Select("Choose", "Select fruit:", ["Apple", "Banana"])
    ; =================================================================
    static Select(title, prompt, optionsArray) {
        Result := ""
        g := this.CreateBaseGui(title)
        g.Add("Text", "w350 c666666", prompt)
        g.Add("DropDownList", "y+8 w350 Choose1 vValue", optionsArray)
        this.AddButtons(g, (*) => (Result := g["Value"].Text, g.Destroy()))
        g.Show()
        WinWaitClose("ahk_id " g.Hwnd)
        return Result
    }

    ; =================================================================
    ; 4. Date Picker (日期选择)
    ; usage: date := Form.Date("Schedule", "Start Date:", "2023-01-01")
    ; =================================================================
    static Date(title, prompt, defaultDate := "") {
        Result := ""
        g := this.CreateBaseGui(title)
        g.Add("Text", "w300 c666666", prompt)
        ; Choose string can be empty (current date) or YYYYMMDD
        opt := (defaultDate != "") ? "Choose" defaultDate : ""
        g.Add("DateTime", "y+8 w300 h32 vValue " opt, "yyyy-MM-dd")
        this.AddButtons(g, (*) => (Result := g["Value"].Text, g.Destroy()))
        g.Show()
        WinWaitClose("ahk_id " g.Hwnd)
        return Result
    }

    ; =================================================================
    ; 5. Confirm Dialog (确认框)
    ; usage: if Form.Confirm("Warning", "Are you sure?") { ... }
    ; returns: true / false
    ; =================================================================
    static Confirm(title, message) {
        Result := false
        g := this.CreateBaseGui(title)
        g.Add("Text", "w300 c333333 +Wrap", message)
        
        g.Add("Text", "y+20 w300 h1 0x10") ; Divider
        g.SetFont("s10")
        
        btnOK := g.Add("Button", "y+10 w100 x50 h32 Default", "OK")
        btnOK.OnEvent("Click", (*) => (Result := true, g.Destroy()))
        
        btnCancel := g.Add("Button", "x+10 w100 h32", "Cancel")
        btnCancel.OnEvent("Click", (*) => (Result := false, g.Destroy()))
        
        g.Show()
        WinWaitClose("ahk_id " g.Hwnd)
        return Result
    }

    ; =================================================================
    ; 6. Form Render (万能表单构建器)
    ; usage: data := Form.Render("Title", [{Type:"Text", Name:"key", Label:"Lbl"}])
    ; returns: Map object
    ; =================================================================
    static Render(title, fields) {
        Result := Map() 
        g := this.CreateBaseGui(title)
        
        for i, field in fields {
            padding := (i=1) ? "" : "y+12"
            
            ; Render Label
            if HasProp(field, "Label")
                g.Add("Text", "w350 c666666 " padding, field.Label)
            
            ; Render Control
            switch field.Type {
                case "Text", "Edit":
                    def := HasProp(field, "Default") ? field.Default : ""
                    g.Add("Edit", "y+5 w350 h32 -E0x200 +Border v" field.Name, def)
                    
                case "Select", "DDL":
                    opts := HasProp(field, "Options") ? field.Options : []
                    g.Add("DropDownList", "y+5 w350 Choose1 v" field.Name, opts)
                    
                case "Check", "Checkbox":
                    def := (HasProp(field, "Default") && field.Default) ? "Checked" : ""
                    g.Add("Checkbox", "y+5 w350 h25 " def " v" field.Name, field.Label)
                
                case "Date", "DateTime":
                    def := HasProp(field, "Default") ? "Choose" field.Default : ""
                    g.Add("DateTime", "y+5 w350 h32 v" field.Name " " def, "yyyy-MM-dd")
            }
        }
        
        OnSubmit(*) {
            saved := g.Submit()
            for field in fields {
                if HasProp(saved, field.Name)
                    Result[field.Name] := saved.%field.Name%
            }
            g.Destroy()
        }

        this.AddButtons(g, OnSubmit)
        g.Show()
        WinWaitClose("ahk_id " g.Hwnd)
        
        if (Result.Count == 0)
            return ""
        return Result
    }

    ; --- Helpers ---
    static CreateBaseGui(title) {
        g := Gui("-MinimizeBox -MaximizeBox +Owner +AlwaysOnTop", title)
        g.BackColor := this.Style.ColorBg
        g.SetFont("s" this.Style.FontSize " c" this.Style.ColorTxt, this.Style.FontName)
        g.MarginX := 25
        g.MarginY := 25

        g.OnEvent("Escape", (*) => g.Destroy())
        g.OnEvent("Close", (*) => g.Destroy())
        
        return g
    }

    static AddButtons(g, submitCallback) {
        g.Add("Text", "y+25 w" (g.MarginX * 2 + 300) " h1 0x10") ; Dynamic Divider
        g.SetFont("s10")
        
        ; Center buttons calculation roughly
        btnOK := g.Add("Button", "y+12 w100 x75 h32 Default", "确定")
        btnOK.OnEvent("Click", submitCallback)
        
        btnCancel := g.Add("Button", "x+15 w100 h32", "取消")
        btnCancel.OnEvent("Click", (*) => g.Destroy())
    }
}