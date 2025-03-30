# Format-Conversion
将b站缓存视频转换成MP4格式

#### ffmpeg
一定要下载并安装了ffmpeg, 一定要添加到系统的环境变量

#### 在powershell中运行下面代码
```powershell
Invoke-PS2EXE -InputFile "d:\Videos\VideoFixer\VideoFixer.ps1" -OutputFile "d:\Videos\VideoFixer\VideoFixer.exe" -IconFile "d:\Videos\VideoFixer\icon.ico" -NoConsole -Title "B站缓存视频格式转换" -Version "1.0.0"
```

【路径名换成自己的】就会生成VideoFixer.exe文件，也可以直接运行上传的VideoFixer.exe文件，根据提示操作即可


