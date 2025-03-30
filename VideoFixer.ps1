Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "视频修复工具"
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = "CenterScreen"

# 视频文件选择
$videoLabel = New-Object System.Windows.Forms.Label
$videoLabel.Location = New-Object System.Drawing.Point(10,20)
$videoLabel.Size = New-Object System.Drawing.Size(280,20)
$videoLabel.Text = "选择视频文件 (.m4s):"
$form.Controls.Add($videoLabel)

$videoButton = New-Object System.Windows.Forms.Button
$videoButton.Location = New-Object System.Drawing.Point(300,20)
$videoButton.Size = New-Object System.Drawing.Size(75,23)
$videoButton.Text = "浏览..."
$form.Controls.Add($videoButton)

# 音频文件选择
$audioLabel = New-Object System.Windows.Forms.Label
$audioLabel.Location = New-Object System.Drawing.Point(10,60)
$audioLabel.Size = New-Object System.Drawing.Size(280,20)
$audioLabel.Text = "选择音频文件 (.m4s):"
$form.Controls.Add($audioLabel)

$audioButton = New-Object System.Windows.Forms.Button
$audioButton.Location = New-Object System.Drawing.Point(300,60)
$audioButton.Size = New-Object System.Drawing.Size(75,23)
$audioButton.Text = "浏览..."
$form.Controls.Add($audioButton)

# 输出目录
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Location = New-Object System.Drawing.Point(10,100)
$outputLabel.Size = New-Object System.Drawing.Size(280,20)
$outputLabel.Text = "输出目录:"
$form.Controls.Add($outputLabel)

$outputButton = New-Object System.Windows.Forms.Button
$outputButton.Location = New-Object System.Drawing.Point(300,100)
$outputButton.Size = New-Object System.Drawing.Size(75,23)
$outputButton.Text = "浏览..."
$form.Controls.Add($outputButton)

# 处理按钮
$processButton = New-Object System.Windows.Forms.Button
$processButton.Location = New-Object System.Drawing.Point(150,150)
$processButton.Size = New-Object System.Drawing.Size(100,30)
$processButton.Text = "开始处理"
$form.Controls.Add($processButton)

# 状态显示
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10,200)
$statusLabel.Size = New-Object System.Drawing.Size(360,40)
$statusLabel.Text = "准备就绪"
$form.Controls.Add($statusLabel)

# 文件选择对话框
$videoFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$videoFileDialog.Filter = "视频文件 (*.m4s)|*.m4s"
$audioFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$audioFileDialog.Filter = "音频文件 (*.m4s)|*.m4s"
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog

# 事件处理
$videoButton.Add_Click({
    if($videoFileDialog.ShowDialog() -eq "OK") {
        $videoLabel.Text = "视频文件: " + $videoFileDialog.FileName
    }
})

$audioButton.Add_Click({
    if($audioFileDialog.ShowDialog() -eq "OK") {
        $audioLabel.Text = "音频文件: " + $audioFileDialog.FileName
    }
})

$outputButton.Add_Click({
    if($folderDialog.ShowDialog() -eq "OK") {
        $outputLabel.Text = "输出目录: " + $folderDialog.SelectedPath
    }
})

$processButton.Add_Click({
    if(-not $videoFileDialog.FileName -or -not $audioFileDialog.FileName -or -not $folderDialog.SelectedPath) {
        $statusLabel.Text = "请先选择所有必要的文件和目录!"
        return
    }
    
    # 直接通过系统PATH查找ffmpeg
    $ffmpegPath = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
    
    if (-not $ffmpegPath) {
        # 尝试在程序目录查找
        $localFfmpeg = Join-Path $PSScriptRoot "ffmpeg.exe"
        if (Test-Path $localFfmpeg) {
            $ffmpegPath = $localFfmpeg
        } else {
            [System.Windows.Forms.MessageBox]::Show("未找到FFmpeg，请安装或将其放入程序目录", "错误", "OK", "Error")
            return
        }
    }
    
    $statusLabel.Text = "正在处理视频文件..."
    $form.Refresh()
    
    try {
        # 处理视频文件
        $inStream = [System.IO.File]::OpenRead($videoFileDialog.FileName)
        $outStream = [System.IO.File]::Create((Join-Path $folderDialog.SelectedPath "video_fixed.m4s"))
        $inStream.Seek(9, [System.IO.SeekOrigin]::Begin)
        $buffer = New-Object byte[] (1024*1024)
        while ($bytesRead = $inStream.Read($buffer, 0, $buffer.Length)) {
            $outStream.Write($buffer, 0, $bytesRead)
        }
        $inStream.Close()
        $outStream.Close()
        
        $statusLabel.Text = "正在处理音频文件..."
        $form.Refresh()
        
        # 处理音频文件
        $inStream = [System.IO.File]::OpenRead($audioFileDialog.FileName)
        $outStream = [System.IO.File]::Create((Join-Path $folderDialog.SelectedPath "audio_fixed.m4s"))
        $inStream.Seek(9, [System.IO.SeekOrigin]::Begin)
        $buffer = New-Object byte[] (1024*1024)
        while ($bytesRead = $inStream.Read($buffer, 0, $buffer.Length)) {
            $outStream.Write($buffer, 0, $bytesRead)
        }
        $inStream.Close()
        $outStream.Close()
        
        $statusLabel.Text = "正在合并音视频..."
        $form.Refresh()
        
        # 合并文件
        $videoPath = Join-Path $folderDialog.SelectedPath "video_fixed.m4s"
        $audioPath = Join-Path $folderDialog.SelectedPath "audio_fixed.m4s"
        $outputPath = Join-Path $folderDialog.SelectedPath "output.mp4"
              
        # 修改FFmpeg调用部分，忽略版权信息输出
        & $ffmpegPath -i $videoPath -i $audioPath -c copy $outputPath 2>&1 | Out-Null
        
        # 添加处理结果验证
        if (Test-Path $outputPath) {
            $statusLabel.Text = "处理完成! 输出文件: $outputPath"
        } else {
            $statusLabel.Text = "处理失败: 输出文件未生成"
        }
    }
    catch {
        $statusLabel.Text = "处理出错: $_"
    }
})

$form.ShowDialog() | Out-Null