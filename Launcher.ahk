; Launcher.ahk
; Bootstrapper: Scans Commands and Texts, compiles runtime script.
#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon  ; 启动器自身不显示图标

class Bootstrapper {
    static Run() {
        rootDir := A_ScriptDir
        libPath := rootDir "\Lib\Core.ahk"
        cmdDir  := rootDir "\Commands"
        txtDir  := rootDir "\Texts" 
        
        ; 临时文件路径
        tempScript := A_Temp "\AHKCommand_Runtime.ahk"

        if !FileExist(libPath) {
            MsgBox("Error: Lib\Core.ahk not found!")
            ExitApp
        }

        scriptContent := ""
        scriptContent .= "#Requires AutoHotkey v2.0`n"
        scriptContent .= "#SingleInstance Force`n"
        scriptContent .= "SetWorkingDir `"" rootDir "`"`n"
        scriptContent .= "#Include `"" libPath "`"`n"

        ;引入表单库
        formPath := rootDir "\Lib\Form.ahk"
        if FileExist(formPath)
            scriptContent .= "#Include `"" formPath "`"`n"
        
        ; 引入用户命令脚本
        if DirExist(cmdDir) {
            Loop Files, cmdDir "\*.ahk" {
                scriptContent .= "#Include `"" A_LoopFileFullPath "`"`n"
            }
        }

        ; 生成文本加载指令
        if DirExist(txtDir) {
            Loop Files, txtDir "\*.txt", "R" 
            {
                fileName := A_LoopFileName
                ; 修复：查找最后一个点，处理文件名中有多个点的情况（如"新闻(新媒体).txt"）
                lastDotPos := InStr(fileName, ".", , -1)
                if (lastDotPos > 0)
                    nameNoExt := SubStr(fileName, 1, lastDotPos - 1)
                else
                    nameNoExt := fileName  ; 没有扩展名的情况
                
                parts := StrSplit(nameNoExt, "__", , 2)
                trigger := parts[1]
                desc := (parts.Length > 1) ? parts[2] : ""

                safePath := StrReplace(A_LoopFileFullPath, "`"", "`"`"")
                scriptContent .= "App.LoadText(`"" safePath "`", `"" trigger "`", `"" desc "`")`n"
            }
        }

        ; [关键修改] 将项目根目录路径传递给 Init 函数
        scriptContent .= "`nApp.Init(`"" rootDir "`")"

        try {
            if FileExist(tempScript)
                FileDelete(tempScript)
            FileAppend(scriptContent, tempScript, "UTF-8")
            
            ; 隐藏启动，无窗口闪烁
            Run(A_AhkPath " `"" tempScript "`"", , "Hide")
        } catch as err {
            MsgBox("Failed to launch: " err.Message)
        }
    }
}

Bootstrapper.Run()