Add-Type -AssemblyName System.Drawing
$outDirs = @(
    "H:\Projects\ThomasThanos\StreamDeck-DiscordVolumeMixer-2026\dist\icons",
    "H:\Projects\ThomasThanos\StreamDeck-DiscordVolumeMixer-2026\bin\Release\cz.danol.discordmixer.sdPlugin\icons",
    "$env:APPDATA\Elgato\StreamDeck\Plugins\cz.danol.discordmixer.sdPlugin\icons"
)

foreach ($dir in $outDirs) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

function Save-IconPair($bmp144, $baseName) {
    # Create 72x72 scaled copy
    $bmp72 = New-Object System.Drawing.Bitmap(72, 72, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g72 = [System.Drawing.Graphics]::FromImage($bmp72)
    $g72.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g72.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g72.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g72.DrawImage($bmp144, 0, 0, 72, 72)
    $g72.Dispose()

    foreach ($dir in $outDirs) {
        $p2x = Join-Path $dir "$baseName@2x.png"
        $p1x = Join-Path $dir "$baseName.png"
        $bmp144.Save($p2x, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp72.Save($p1x, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    $bmp72.Dispose()
    Write-Host "Generated: $baseName (@2x and 1x)"
}

function Create-RoundedRectPath([System.Drawing.RectangleF]$rect, [float]$radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = [float]($radius * 2.0)
    $x = [float]$rect.X
    $y = [float]$rect.Y
    $w = [float]$rect.Width
    $h = [float]$rect.Height

    # Top Left
    $path.AddArc($x, $y, $d, $d, 180.0, 90.0)
    # Top Right
    $path.AddArc(($x + $w - $d), $y, $d, $d, 270.0, 90.0)
    # Bottom Right
    $path.AddArc(($x + $w - $d), ($y + $h - $d), $d, $d, 0.0, 90.0)
    # Bottom Left
    $path.AddArc($x, ($y + $h - $d), $d, $d, 90.0, 90.0)
    $path.CloseFigure()
    return $path
}

function Draw-AppleTile([System.Drawing.Graphics]$g, [System.Drawing.RectangleF]$rect, [System.Drawing.Color]$topCol, [System.Drawing.Color]$botCol, [float]$radius = 28.0) {
    # 1. Ambient Drop Shadow
    $shadowRect = [System.Drawing.RectangleF]::new($rect.X, $rect.Y + 4, $rect.Width, $rect.Height)
    $shadowPath = Create-RoundedRectPath $shadowRect $radius
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90, 0, 0, 0))
    $g.FillPath($shadowBrush, $shadowPath)
    $shadowBrush.Dispose()
    $shadowPath.Dispose()

    # 2. Main Squircle Body Gradient
    $tilePath = Create-RoundedRectPath $rect $radius
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topCol, $botCol, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $g.FillPath($bgBrush, $tilePath)
    $bgBrush.Dispose()

    # 3. Inner Bevel / Glass Hairline Highlight
    $rimBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(140, 255, 255, 255), [System.Drawing.Color]::FromArgb(30, 0, 0, 0), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $rimPen = New-Object System.Drawing.Pen($rimBrush, 1.6)
    $g.DrawPath($rimPen, $tilePath)
    $rimPen.Dispose()
    $rimBrush.Dispose()

    # 4. Top Glass Specular Shine
    $shineRect = [System.Drawing.RectangleF]::new($rect.X + 6, $rect.Y + 2, $rect.Width - 12, ($rect.Height / 2.2))
    $shinePath = Create-RoundedRectPath $shineRect ($radius * 0.75)
    $shineBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($shineRect, [System.Drawing.Color]::FromArgb(55, 255, 255, 255), [System.Drawing.Color]::FromArgb(0, 255, 255, 255), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $g.FillPath($shineBrush, $shinePath)
    $shineBrush.Dispose()
    $shinePath.Dispose()

    $tilePath.Dispose()
}

# 1. Discord Main Icon (3D Apple Blurple Tile + 3D Clyde Face)
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x6E, 0x7B, 0xFA)) ([System.Drawing.Color]::FromArgb(0x3B, 0x46, 0xC4)) 30.0

# 3D Clyde Face Path
$clyde = New-Object System.Drawing.Drawing2D.GraphicsPath
$clyde.StartFigure()
$clyde.AddBezier(36, 56, 52, 42, 92, 42, 108, 56)
$clyde.AddBezier(108, 56, 116, 82, 108, 104)
$clyde.AddLine(108, 104, 98, 96)
$clyde.AddLine(98, 96, 88, 102)
$clyde.AddLine(88, 102, 56, 102)
$clyde.AddLine(56, 102, 46, 96)
$clyde.AddLine(46, 96, 36, 104)
$clyde.AddBezier(36, 104, 28, 82, 36, 56)
$clyde.CloseFigure()

# Drop Shadow under Clyde
$clydeShadow = New-Object System.Drawing.Drawing2D.Matrix
$clydeShadow.Translate(0, 2.5)
$clyde.Transform($clydeShadow)
$g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 0, 0))), $clyde)
$clydeShadow.Translate(0, -2.5)
$clyde.Transform($clydeShadow)

# Clyde Pearl Body
$clydeBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    ([System.Drawing.RectangleF]::new(36, 42, 72, 62)),
    [System.Drawing.Color]::FromArgb(255, 255, 255),
    [System.Drawing.Color]::FromArgb(228, 233, 242),
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
)
$g.FillPath($clydeBrush, $clyde)
$g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1.2)), $clyde)

# Clyde Eyes
$eyeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0x40, 0x4E, 0xED))
$g.FillEllipse($eyeBrush, ([System.Drawing.RectangleF]::new(53, 68, 10, 14)))
$g.FillEllipse($eyeBrush, ([System.Drawing.RectangleF]::new(81, 68, 10, 14)))

$g.Dispose()
Save-IconPair $bmp "icons8_discord_new_72px"
$bmp.Dispose()

# 2. Microphone (3D Studio Mic + Active Glow)
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x2B, 0x2D, 0x31)) ([System.Drawing.Color]::FromArgb(0x15, 0x16, 0x18)) 30.0

# Neon Audio Halo
$haloBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush((Create-RoundedRectPath ([System.Drawing.RectangleF]::new(36, 32, 72, 72)) 36))
$haloBrush.CenterColor = [System.Drawing.Color]::FromArgb(90, 0x23, 0xA5, 0x5A)
$haloBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0x23, 0xA5, 0x5A))
$g.FillRectangle($haloBrush, 36, 32, 72, 72)
$haloBrush.Dispose()

# Mic Capsule
$micRect = [System.Drawing.RectangleF]::new(58, 32, 28, 44)
$micPath = Create-RoundedRectPath $micRect 14
$micBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($micRect, [System.Drawing.Color]::FromArgb(255, 255, 255), [System.Drawing.Color]::FromArgb(0x23, 0xA5, 0x5A), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$g.FillPath($micBrush, $micPath)
$g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 255), 1.5)), $micPath)
$micBrush.Dispose()
$micPath.Dispose()

# Mic Stand / Bracket
$standPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(240, 243, 246), 4.5)
$standPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$standPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawArc($standPen, ([System.Drawing.RectangleF]::new(49, 48, 46, 44)), 0, 180)
$g.DrawLine($standPen, 72, 92, 72, 104)
$g.DrawLine($standPen, 56, 104, 88, 104)
$standPen.Dispose()

$g.Dispose()
Save-IconPair $bmp "icons8_microphone_72px"

# 3. Microphone Muted (with 3D Apple Red Slash)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

$slashShadow = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 0, 0, 0), 8.5)
$slashShadow.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$slashShadow.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($slashShadow, 35, 111, 109, 37)

$redBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(([System.Drawing.RectangleF]::new(34, 34, 76, 76)), [System.Drawing.Color]::FromArgb(0xFF, 0x5C, 0x5C), [System.Drawing.Color]::FromArgb(0xED, 0x42, 0x45), [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
$slashPen = New-Object System.Drawing.Pen($redBrush, 6.5)
$slashPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$slashPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($slashPen, 34, 110, 110, 34)

$slashShadow.Dispose()
$slashPen.Dispose()
$redBrush.Dispose()
$g.Dispose()

Save-IconPair $bmp "icons8_block_microphone_72px"
$bmp.Dispose()

# 4. Speaker / Sound
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x2B, 0x2D, 0x31)) ([System.Drawing.Color]::FromArgb(0x15, 0x16, 0x18)) 30.0

# Speaker Cone
$cone = New-Object System.Drawing.Drawing2D.GraphicsPath
$cone.AddLine(28, 60, 44, 60)
$cone.AddLine(44, 60, 66, 44)
$cone.AddLine(66, 44, 66, 100)
$cone.AddLine(66, 100, 44, 84)
$cone.AddLine(44, 84, 28, 84)
$cone.CloseFigure()

$coneBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(([System.Drawing.RectangleF]::new(28, 44, 38, 56)), [System.Drawing.Color]::FromArgb(255, 255, 255), [System.Drawing.Color]::FromArgb(0x58, 0x65, 0xF2), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$g.FillPath($coneBrush, $cone)
$g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 255), 1.5)), $cone)
$coneBrush.Dispose()
$cone.Dispose()

# Soundwaves
$wPen1 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0xDB, 0xDE, 0xE1), 4.0); $wPen1.StartCap = $wPen1.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$wPen2 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0x58, 0x65, 0xF2), 4.0); $wPen2.StartCap = $wPen2.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$wPen3 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0x23, 0xA5, 0x5A), 4.0); $wPen3.StartCap = $wPen3.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

$g.DrawArc($wPen1, ([System.Drawing.RectangleF]::new(56, 56, 32, 32)), -50, 100)
$g.DrawArc($wPen2, ([System.Drawing.RectangleF]::new(66, 46, 52, 52)), -50, 100)
$g.DrawArc($wPen3, ([System.Drawing.RectangleF]::new(76, 36, 72, 72)), -50, 100)

$wPen1.Dispose(); $wPen2.Dispose(); $wPen3.Dispose()
$g.Dispose()

Save-IconPair $bmp "icons8_speaker_72px"

# 5. No Audio / Deafened (Speaker + Red Slash)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

$slashShadow = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 0, 0, 0), 8.5)
$slashShadow.StartCap = $slashShadow.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($slashShadow, 35, 111, 109, 37)

$redBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(([System.Drawing.RectangleF]::new(34, 34, 76, 76)), [System.Drawing.Color]::FromArgb(0xFF, 0x5C, 0x5C), [System.Drawing.Color]::FromArgb(0xED, 0x42, 0x45), [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
$slashPen = New-Object System.Drawing.Pen($redBrush, 6.5)
$slashPen.StartCap = $slashPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($slashPen, 34, 110, 110, 34)

$slashShadow.Dispose(); $slashPen.Dispose(); $redBrush.Dispose()
$g.Dispose()

Save-IconPair $bmp "icons8_no_audio_72px"
$bmp.Dispose()

# 6. Plus Math / Volume Up (3D Embossed Plus)
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x2B, 0x2D, 0x31)) ([System.Drawing.Color]::FromArgb(0x15, 0x16, 0x18)) 30.0

$plusH = Create-RoundedRectPath ([System.Drawing.RectangleF]::new(48, 66, 48, 12)) 6
$plusV = Create-RoundedRectPath ([System.Drawing.RectangleF]::new(66, 48, 12, 48)) 6
$plusBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(([System.Drawing.RectangleF]::new(48, 48, 48, 48)), [System.Drawing.Color]::FromArgb(255, 255, 255), [System.Drawing.Color]::FromArgb(0x57, 0xF2, 0x87), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$plusPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(220, 255, 255, 255), 1.2)

$g.FillPath($plusBrush, $plusH); $g.DrawPath($plusPen, $plusH)
$g.FillPath($plusBrush, $plusV); $g.DrawPath($plusPen, $plusV)

$plusH.Dispose(); $plusV.Dispose(); $plusBrush.Dispose(); $plusPen.Dispose()
$g.Dispose()
Save-IconPair $bmp "icons8_plus_math_72px"
$bmp.Dispose()

# 7. Minus Math / Volume Down (3D Embossed Minus)
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x2B, 0x2D, 0x31)) ([System.Drawing.Color]::FromArgb(0x15, 0x16, 0x18)) 30.0

$minusH = Create-RoundedRectPath ([System.Drawing.RectangleF]::new(48, 66, 48, 12)) 6
$minusBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(([System.Drawing.RectangleF]::new(48, 66, 48, 12)), [System.Drawing.Color]::FromArgb(255, 255, 255), [System.Drawing.Color]::FromArgb(0x8E, 0xA0, 0xFF), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$minusPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(220, 255, 255, 255), 1.2)

$g.FillPath($minusBrush, $minusH); $g.DrawPath($minusPen, $minusH)

$minusH.Dispose(); $minusBrush.Dispose(); $minusPen.Dispose()
$g.Dispose()
Save-IconPair $bmp "icons8_minus_72px"
$bmp.Dispose()

# 8. Arrow Up / Back Navigation
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x2B, 0x2D, 0x31)) ([System.Drawing.Color]::FromArgb(0x15, 0x16, 0x18)) 30.0

$arrow = New-Object System.Drawing.Drawing2D.GraphicsPath
$arrow.AddLine(72, 46, 96, 70)
$arrow.AddLine(96, 70, 84, 70)
$arrow.AddLine(84, 70, 84, 98)
$arrow.AddLine(84, 98, 60, 98)
$arrow.AddLine(60, 98, 60, 70)
$arrow.AddLine(60, 70, 48, 70)
$arrow.CloseFigure()

$arrBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(([System.Drawing.RectangleF]::new(48, 46, 48, 52)), [System.Drawing.Color]::FromArgb(255, 255, 255), [System.Drawing.Color]::FromArgb(0xDB, 0xDE, 0xE1), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$g.FillPath($arrBrush, $arrow)
$g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 255), 1.2)), $arrow)

$arrow.Dispose(); $arrBrush.Dispose(); $g.Dispose()
Save-IconPair $bmp "icons8_arrow_up_72px"
$bmp.Dispose()

# 9. Sort Left / Previous Page
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x2B, 0x2D, 0x31)) ([System.Drawing.Color]::FromArgb(0x15, 0x16, 0x18)) 30.0

$chevPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255), 7.0)
$chevPen.StartCap = $chevPen.EndCap = $chevPen.LineJoin = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLines($chevPen, [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(84, 48),
    [System.Drawing.PointF]::new(58, 72),
    [System.Drawing.PointF]::new(84, 96)
))
$chevPen.Dispose(); $g.Dispose()
Save-IconPair $bmp "icons8_sort_left_72px"
$bmp.Dispose()

# 10. Sort Right / Next Page
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x2B, 0x2D, 0x31)) ([System.Drawing.Color]::FromArgb(0x15, 0x16, 0x18)) 30.0

$chevPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255), 7.0)
$chevPen.StartCap = $chevPen.EndCap = $chevPen.LineJoin = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLines($chevPen, [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(60, 48),
    [System.Drawing.PointF]::new(86, 72),
    [System.Drawing.PointF]::new(60, 96)
))
$chevPen.Dispose(); $g.Dispose()
Save-IconPair $bmp "icons8_sort_right_72px"
$bmp.Dispose()

# 11. User Avatar Placeholder
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x2B, 0x2D, 0x31)) ([System.Drawing.Color]::FromArgb(0x15, 0x16, 0x18)) 30.0

$head = New-Object System.Drawing.Drawing2D.GraphicsPath
$head.AddEllipse(54, 40, 36, 36)

$body = New-Object System.Drawing.Drawing2D.GraphicsPath
$body.AddArc(([System.Drawing.RectangleF]::new(42, 80, 60, 50)), 180, 180)
$body.CloseFigure()

$userBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(([System.Drawing.RectangleF]::new(42, 40, 60, 60)), [System.Drawing.Color]::FromArgb(255, 255, 255), [System.Drawing.Color]::FromArgb(0x94, 0x9B, 0xA4), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$g.FillPath($userBrush, $head); $g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1.2)), $head)
$g.FillPath($userBrush, $body); $g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1.2)), $body)

$head.Dispose(); $body.Dispose(); $userBrush.Dispose(); $g.Dispose()
Save-IconPair $bmp "icons8_user_72px"
$bmp.Dispose()

# 12. No Icon (Frosted Dark Glass Tile)
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

Draw-AppleTile $g ([System.Drawing.RectangleF]::new(10, 10, 124, 124)) ([System.Drawing.Color]::FromArgb(0x2B, 0x2D, 0x31)) ([System.Drawing.Color]::FromArgb(0x15, 0x16, 0x18)) 30.0
$g.Dispose()
Save-IconPair $bmp "noicon"
$bmp.Dispose()

# 13. Speaking Decoration (3D Neon Discord Green Glow Ring)
$bmp = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

$ringRect = [System.Drawing.RectangleF]::new(8, 8, 128, 128)

# Multi-layer Outer Glow
for ($i = 5; $i -ge 1; $i--) {
    $adj = $i * 1.5
    $gPath = Create-RoundedRectPath ([System.Drawing.RectangleF]::new($ringRect.X - $adj, $ringRect.Y - $adj, $ringRect.Width + ($adj*2), $ringRect.Height + ($adj*2))) (26 + $i)
    $gPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb([int](35 / $i), 0x23, 0xA5, 0x5A), 2.0)
    $g.DrawPath($gPen, $gPath)
    $gPen.Dispose(); $gPath.Dispose()
}

# Core Glowing Ring
$coreRing = Create-RoundedRectPath $ringRect 24
$neonBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($ringRect, [System.Drawing.Color]::FromArgb(0x57, 0xF2, 0x87), [System.Drawing.Color]::FromArgb(0x23, 0xA5, 0x5A), [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
$neonPen = New-Object System.Drawing.Pen($neonBrush, 5.5)
$neonPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$g.DrawPath($neonPen, $coreRing)

# Inner Hairline Specular
$innerRect = [System.Drawing.RectangleF]::new($ringRect.X + 2.5, $ringRect.Y + 2.5, $ringRect.Width - 5, $ringRect.Height - 5)
$innerRing = Create-RoundedRectPath $innerRect 22
$g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(160, 255, 255, 255), 1.2)), $innerRing)

$innerRing.Dispose(); $coreRing.Dispose(); $neonPen.Dispose(); $neonBrush.Dispose(); $g.Dispose()

foreach ($dir in $outDirs) {
    $p = Join-Path $dir "speaking_deco.png"
    $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
}
$bmp.Dispose()
Write-Host "Generated: speaking_deco.png"

Write-Host "All 3D Apple-style icons refactored & deployed successfully!"



