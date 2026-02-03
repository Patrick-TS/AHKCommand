#Requires AutoHotkey v2.0

; Calculate path to Texts folder.
SplitPath(A_LineFile,, &Dir) ; Dir is directory of current file (Lib)
RootTextsDir := Dir "\..\Texts"

; Scan for subdirectories
SubDirs := []
if DirExist(RootTextsDir)
{
    Loop Files, RootTextsDir "\*", "D"
    {
        SubDirs.Push(A_LoopFileName)
    }
}

MyGui := Gui(, "Add New Text File")
MyGui.SetFont("s10", "Segoe UI")

MyGui.Add("Text",, "Select Directory:")
; Add "Root" option and then subdirectories
DirItems := ["/ (Root)"]
for FolderName in SubDirs
    DirItems.Push(FolderName)

ddlDir := MyGui.Add("DropDownList", "w400 Choose1", DirItems)

MyGui.Add("Text",, "Filename (without extension):")
EdFileName := MyGui.Add("Edit", "w400")

MyGui.Add("Text",, "Content:")
EdContent := MyGui.Add("Edit", "r10 w400")

BtnCreate := MyGui.Add("Button", "Default w80", "Create")
BtnCreate.OnEvent("Click", CreateFile)

MyGui.Show()

CreateFile(*)
{
    SelectedDir := ddlDir.Text
    FileName := EdFileName.Value
    FileContent := EdContent.Value

    if (FileName = "")
    {
        MsgBox("Please enter a filename.", "Error", "Icon!")
        return
    }

    if (SelectedDir = "/ (Root)")
        TargetDir := RootTextsDir
    else
        TargetDir := RootTextsDir "\" SelectedDir

    if !DirExist(TargetDir)
    {
        try {
            DirCreate(TargetDir)
        } catch as err {
             MsgBox("Failed to create directory: " TargetDir "`nError: " err.Message, "Error", "Icon!")
             return
        }
    }

    FilePath := TargetDir "\" FileName ".txt"

    if FileExist(FilePath)
    {
        Result := MsgBox("File already exists. Overwrite?", "Warning", "YesNo Icon!")
        if (Result = "No")
            return
    }

    try {
        if FileExist(FilePath)
            FileDelete(FilePath)
        FileAppend(FileContent, FilePath, "UTF-8")
        MsgBox("File '" FileName ".txt' created in '" (SelectedDir = "/ (Root)" ? "Texts" : SelectedDir) "' successfully!", "Success")
        MyGui.Destroy()
    } catch as err {
        MsgBox("Failed to save file.`nError: " err.Message, "Error", "Icon!")
    }
}
