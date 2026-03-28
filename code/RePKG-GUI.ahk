#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon
;@Ahk2Exe-SetName        RePKG-GUI
;@Ahk2Exe-SetVersion     1.0.0
;@Ahk2Exe-SetCompanyName Zerin
;@Ahk2Exe-SetCopyright   Copyright © 2026 Zerin
;@Ahk2Exe-SetDescription RePKG-GUI
;@Ahk2Exe-SetLanguage    0x0804

DllCall("SetProcessDPIAware")

GetFileDescription(filePath) {
    psCmd := Format('(Get-Item "{1}").VersionInfo.FileDescription', filePath)
    try {
        tempFile := A_Temp . "\repkg_desc.txt"
        RunWait(A_ComSpec . ' /c powershell -NoProfile -Command "' . psCmd . '" > "' . tempFile . '"', , "Hide")
        desc := Trim(FileRead(tempFile), "`r`n`t ")
        FileDelete(tempFile)
        return desc
    }
    return ""
}

FindRePKG() {
    Loop Files A_ScriptDir . "\*.exe" {
        try {
            desc := GetFileDescription(A_LoopFileFullPath)
            if (desc = "RePKG") {
                return A_LoopFileFullPath
            }
        }
    }
    return ""
}

repkgPath := FindRePKG()

if (repkgPath = "") {
    DllCall("user32\MessageBox", "Ptr", 0, "Str", "未找到 RePKG.exe ,请手动下载 RePKG.exe 到程序同目录", "Str", "错误", "UInt", 0x10)
    Run("https://github.com/notscuffed/repkg/releases")
    ExitApp
}

global TargetFile := ""
global OutputDir := ""
global SizeValue := 100
global SizeUnit := "MB"
global StatusText := "就绪"
global LastSplitFile := ""

mainGui := Gui()
mainGui.Title := "RePKG-GUI"
mainGui.BackColor := "0xF0F0F0"

mainGui.SetFont("s16", "Microsoft YaHei")
mainGui.Add("Text", "x15 y10 w460 ", "RePKG-GUI")

mainGui.SetFont("s13", "Microsoft YaHei")
mainGui.Add("Text", "x15 y50 w100 h25", "目标文件:")
mainGui.SetFont("s12", "Microsoft YaHei")
TargetFileEdit := mainGui.Add("Edit", "x95 y50 w350 h25")
mainGui.SetFont("s13", "Microsoft YaHei")
BrowseFileBtn := mainGui.Add("Button", "x450 y50 w50 h25 Center", "浏览")

mainGui.SetFont("s13", "Microsoft YaHei")
mainGui.Add("Text", "x15 y85 w100 h25", "输出目录:")
mainGui.SetFont("s12", "Microsoft YaHei")
OutputDirEdit := mainGui.Add("Edit", "x95 y85 w350 h25")
mainGui.SetFont("s13", "Microsoft YaHei")
BrowseDirBtn := mainGui.Add("Button", "x450 y85 w50 h25 Center", "浏览")
mainGui.Add("Text", "x15 y125 w485 h1 BackgroundC0C0C0")

mainGui.SetFont("s13", "Microsoft YaHei")
PartButton := mainGui.Add("Button", "x15 y145 w140 h30 Center", "提取媒体文件")
ALLButton := mainGui.Add("Button", "x200 y145 w140 h30 Center", "提取所有文件")

mainGui.Add("Text", "x15 y210 w60 h25", "状态:")
StatusLabel := mainGui.Add("Text", "x61 y210 w600 h25", "就绪")

mainGui.Add("Text", "x15 y250 w450 h25", "提示: 点击浏览选择 .pkg 后缀文件以提取")

webLink := MainGui.Add("Text", "x435 y250 w80 h25 cBlue", "GitHub")
webLink.OnEvent("Click", (*) => Run("https://github.com/Zerin-emm/RePKG-GUI"))
BrowseFileBtn.OnEvent("Click", BrowsePkgFile)
BrowseDirBtn.OnEvent("Click", BrowseOutputDir)
ALLButton.OnEvent("Click", ALLFile)
PartButton.OnEvent("Click", PartFile)

mainGui.Show("w520 h290")

BrowsePkgFile(*) {
    global TargetFile, TargetFileEdit, StatusLabel, OutputDir, OutputDirEdit

    selectedFile := FileSelect(1, , "选择PKG文件", "PKG文件 (*.pkg)")
    if (selectedFile != "") {
        TargetFile := selectedFile
        TargetFileEdit.Value := TargetFile
        SplitPath TargetFile, &fileName, &fileDir
        pkgName := StrReplace(fileName, ".pkg", "")
        OutputDir := fileDir . "\" . pkgName
        OutputDirEdit.Value := OutputDir
        StatusLabel.Value := "已选择文件: " . fileName
    }
}

BrowseOutputDir(*) {
    global OutputDir, OutputDirEdit, StatusLabel

    selectedDir := FileSelect("D", , "选择输出目录")
    if (selectedDir != "") {
        OutputDir := selectedDir
        OutputDirEdit.Value := OutputDir
        StatusLabel.Value := "已选择目录: " . OutputDir
    }
}

PartFile(*) {
    global TargetFile, OutputDir, StatusLabel

    if (TargetFile = "" || !FileExist(TargetFile)) {
        DllCall("user32\MessageBox", "Ptr", mainGui.Hwnd, "Str", "请先选择一个有效的文件", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请先选择一个有效的文件"
        return
    }

    if (!InStr(TargetFile, ".pkg")) {
        DllCall("user32\MessageBox", "Ptr", mainGui.Hwnd, "Str", "请选择 .pkg 文件进行提取", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请选择 .pkg 文件进行提取"
        return
    }

    if (OutputDir = "") {
        DllCall("user32\MessageBox", "Ptr", mainGui.Hwnd, "Str", "请先选择输出目录", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请先选择输出目录"
        return
    }

    StatusLabel.Value := "正在提取 PNG/MP4/GIF..."
    cmd := Format('"{1}" extract -e tex -s -o "{2}" "{3}"', repkgPath, OutputDir, TargetFile)
    try {
        exitCode := RunWait(A_ComSpec " /c " cmd, , "Hide")
        if (exitCode = 0) {
            Loop Files OutputDir . "\*.tex-json"
                FileDelete A_LoopFilePath
            Loop Files OutputDir . "\*.tex"
                FileDelete A_LoopFilePath
            DllCall("user32\MessageBox", "Ptr", mainGui.Hwnd, "Str", "成功提取媒体文件", "Str", "完成", "UInt", 0x40)
            Run("explorer.exe " . OutputDir)
            StatusLabel.Value := "提取完成！"
        } else {
            StatusLabel.Value := "提取失败，错误代码: " . exitCode
        }
    } catch Error as err {
        StatusLabel.Value := "错误: " . err.Message
    }
}

ALLFile(*) {
    global TargetFile, OutputDir, StatusLabel

    if (TargetFile = "" || !FileExist(TargetFile)) {
        DllCall("user32\MessageBox", "Ptr", mainGui.Hwnd, "Str", "请先选择一个有效的文件", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请先选择一个有效的文件"
        return
    }

    if (!InStr(TargetFile, ".pkg")) {
        DllCall("user32\MessageBox", "Ptr", mainGui.Hwnd, "Str", "请选择 .pkg 文件进行提取", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请选择 .pkg 文件进行提取"
        return
    }

    if (OutputDir = "") {
        DllCall("user32\MessageBox", "Ptr", mainGui.Hwnd, "Str", "请先选择输出目录", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请先选择输出目录"
        return
    }

    StatusLabel.Value := "正在提取所有文件..."
    cmd := Format('"{1}" extract -o "{2}" "{3}"', repkgPath, OutputDir, TargetFile)
    try {
        exitCode := RunWait(A_ComSpec " /c " cmd, , "Hide")
        if (exitCode = 0) {
            DllCall("user32\MessageBox", "Ptr", mainGui.Hwnd, "Str", "成功提取所有文件", "Str", "完成", "UInt", 0x40)
            Run("explorer.exe " . OutputDir)
            StatusLabel.Value := "提取完成！"
        } else {
            StatusLabel.Value := "提取失败，错误代码: " . exitCode
        }
    } catch Error as err {
        StatusLabel.Value := "错误: " . err.Message
    }
}

