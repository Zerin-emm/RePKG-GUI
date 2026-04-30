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

timestamp := FormatTime(, "yyyyMMddHHmmss")
repkgPath := A_Temp . "\RePKG_" . timestamp . ".exe"
FileInstall("RePKG.exe", repkgPath, 1)

global TargetFile := ""
global OutputDir := ""
global LastSplitFile := ""

MainGui := Gui()
MainGui.Title := "RePKG-GUI"
MainGui.BackColor := "0xF8FBFD"
MainGui.SetFont("s16", "Microsoft YaHei")
MainGui.Add("Text", "x15 y10 w460 ", "RePKG-GUI")
MainGui.SetFont("s13", "Microsoft YaHei")
MainGui.Add("Text", "x15 y50 w100 h25", "目标文件:")
MainGui.SetFont("s12", "Microsoft YaHei")
TargetFileEdit := MainGui.Add("Edit", "x95 y50 w350 h25")
MainGui.SetFont("s13", "Microsoft YaHei")
MainGui.Add("Button", "x450 y50 w50 h25 Center", "浏览").OnEvent("Click", BrowsePkgFile)
MainGui.SetFont("s13", "Microsoft YaHei")
MainGui.Add("Text", "x15 y85 w100 h25", "输出目录:")
MainGui.SetFont("s12", "Microsoft YaHei")
OutputDirEdit := MainGui.Add("Edit", "x95 y85 w350 h25")
MainGui.SetFont("s13", "Microsoft YaHei")
MainGui.Add("Button", "x450 y85 w50 h25 Center", "浏览").OnEvent("Click", BrowseOutputDir)
MainGui.Add("Text", "x15 y125 w485 h1 BackgroundC0C0C0")
MainGui.SetFont("s13", "Microsoft YaHei")
MainGui.Add("Button", "x15 y145 w140 h30 Center", "提取媒体文件").OnEvent("Click", PartFile)
MainGui.Add("Button", "x200 y145 w140 h30 Center", "提取所有文件").OnEvent("Click", ALLFile)
MainGui.Add("Text", "x15 y210 w60 h25", "状态:")
StatusLabel := MainGui.Add("Text", "x61 y210 w600 h25", "就绪")
MainGui.Add("Text", "x15 y250 w450 h25", "提示: 点击浏览选择 .pkg 后缀文件以提取")
MainGui.Add("Text", "x435 y250 w80 h25 cBlue", "GitHub").OnEvent("Click", (*) => Run("https://github.com/Zerin-emm/RePKG-GUI"))

MainGui.Show("w520 h290")

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
        DllCall("user32\MessageBox", "Ptr", MainGui.Hwnd, "Str", "请先选择一个有效的文件", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请先选择一个有效的文件"
        return
    }

    if (!InStr(TargetFile, ".pkg")) {
        DllCall("user32\MessageBox", "Ptr", MainGui.Hwnd, "Str", "请选择 .pkg 文件进行提取", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请选择 .pkg 文件进行提取"
        return
    }

    if (OutputDir = "") {
        DllCall("user32\MessageBox", "Ptr", MainGui.Hwnd, "Str", "请先选择输出目录", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请先选择输出目录"
        return
    }

    StatusLabel.Value := "正在提取 PNG/MP4/GIF..."
    cmd := Format('"{1}" extract -e tex -s -o "{2}" "{3}"', repkgPath, OutputDir, TargetFile)
    
    if (!FileExist(repkgPath)) {
        DllCall("user32\MessageBox", "Ptr", MainGui.Hwnd, "Str", "RePKG.exe 不存在: " . repkgPath, "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: RePKG.exe 不存在"
        return
    }
    
    try {
        exitCode := RunWait(cmd, , "Hide")
        if (exitCode = 0) {
            Loop Files OutputDir . "\*.tex-json"
                FileDelete A_LoopFilePath
            Loop Files OutputDir . "\*.tex"
                FileDelete A_LoopFilePath
            DllCall("user32\MessageBox", "Ptr", MainGui.Hwnd, "Str", "成功提取媒体文件", "Str", "完成", "UInt", 0x40)
            Run(OutputDir)
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
        DllCall("user32\MessageBox", "Ptr", MainGui.Hwnd, "Str", "请先选择一个有效的文件", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请先选择一个有效的文件"
        return
    }

    if (!InStr(TargetFile, ".pkg")) {
        DllCall("user32\MessageBox", "Ptr", MainGui.Hwnd, "Str", "请选择 .pkg 文件进行提取", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请选择 .pkg 文件进行提取"
        return
    }

    if (OutputDir = "") {
        DllCall("user32\MessageBox", "Ptr", MainGui.Hwnd, "Str", "请先选择输出目录", "Str", "错误", "UInt", 0x10)
        StatusLabel.Value := "错误: 请先选择输出目录"
        return
    }

    StatusLabel.Value := "正在提取所有文件..."
    cmd := Format('"{1}" extract -o "{2}" "{3}"', repkgPath, OutputDir, TargetFile)
    try {
        exitCode := RunWait(cmd, , "Hide")
        if (exitCode = 0) {
            DllCall("user32\MessageBox", "Ptr", MainGui.Hwnd, "Str", "成功提取所有文件", "Str", "完成", "UInt", 0x40)
            Run(OutputDir)
            StatusLabel.Value := "提取完成！"
        } else {
            StatusLabel.Value := "提取失败，错误代码: " . exitCode
        }
    } catch Error as err {
        StatusLabel.Value := "错误: " . err.Message
    }
}

MainGui.OnEvent("Close", CloseGui)

CloseGui(*) {
    try FileDelete(repkgPath)
    ExitApp()
}

