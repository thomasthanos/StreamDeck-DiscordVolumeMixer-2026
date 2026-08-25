Add-Type -AssemblyName System.Drawing

$outDirs = @(
    "H:\Projects\ThomasThanos\StreamDeck-DiscordVolumeMixer-2026\dist\icons",
    "H:\Projects\ThomasThanos\StreamDeck-DiscordVolumeMixer-2026\bin\Release\cz.danol.discordmixer.sdPlugin\icons",
    "$env:APPDATA\Elgato\StreamDeck\Plugins\cz.danol.discordmixer.sdPlugin\icons"
)

function Save-IconPair($bmp144, $baseName) {
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

function Create-RoundedRectPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2.0
    $path.AddArc($x, $y, $diameter, $diameter, 180.0, 90.0)
    $path.AddArc(($x + $w - $diameter), $y, $diameter, $diameter, 270.0, 90.0)
    $path.AddArc(($x + $w - $diameter), ($y + $h - $diameter), $diameter, $diameter, 0.0, 90.0)
    $path.AddArc($x, ($y + $h - $diameter), $diameter, $diameter, 90.0, 90.0)
    $path.CloseFigure()
    return $path
}

function Draw-AppleTile([System.Drawing.Graphics]$g, [float]$x, [float]$y, [float]$w, [float]$h, [System.Drawing.Color]$topCol, [System.Drawing.Color]$botCol, [float]$radius = 28.0) {
    $shadowPath = Create-RoundedRectPath $x ($y + 4.0) $w $h $radius
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90, 0, 0, 0))
    $g.FillPath($shadowBrush, $shadowPath)
    $shadowBrush.Dispose()
    $shadowPath.Dispose()

    $tilePath = Create-RoundedRectPath $x $y $w $h $radius
    $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topCol, $botCol, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $g.FillPath($bgBrush, $tilePath)
    $bgBrush.Dispose()

    $rimBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(140, 255, 255, 255), [System.Drawing.Color]::FromArgb(30, 0, 0, 0), [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $rimPen = New-Object System.Drawing.Pen($rimBrush, 1.6)
    $g.DrawPath($rimPen, $tilePath)
    $rimPen.Dispose()
    $rimBrush.Dispose()

    $shineH = [float]($h / 2.2)
    $shinePath = Create-RoundedRectPath ($x + 6.0) ($y + 2.0) ($w - 12.0) $shineH ($radius * 0.75)
    $shineRect = New-Object System.Drawing.RectangleF(($x + 6.0), ($y + 2.0), ($w - 12.0), $shineH)
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

Draw-AppleTile $g 10.0 10.0 124.0 124.0 ([System.Drawing.Color]::FromArgb(0x6E, 0x7B, 0xFA)) ([System.Drawing.Color]::FromArgb(0x3B, 0x46, 0xC4)) 30.0

$clyde = New-Object System.Drawing.Drawing2D.GraphicsPath
$clyde.StartFigure()
$clyde.AddBezier(36.0, 56.0, 52.0, 42.0, 92.0, 42.0, 108.0, 56.0)
$clyde.AddBezier(108.0, 56.0, 114.0, 78.0, 114.0, 92.0, 108.0, 104.0)
$clyde.AddLine(108.0, 104.0, 98.0, 96.0)
$clyde.AddLine(98.0, 96.0, 88.0, 102.0)
$clyde.AddLine(88.0, 102.0, 56.0, 102.0)
$clyde.AddLine(56.0, 102.0, 46.0, 96.0)
$clyde.AddLine(46.0, 96.0, 36.0, 104.0)
$clyde.AddBezier(36.0, 104.0, 30.0, 92.0, 30.0, 78.0, 36.0, 56.0)
$clyde.CloseFigure()

$clydeShadow = New-Object System.Drawing.Drawing2D.Matrix
$clydeShadow.Translate(0, 2.5)
$clyde.Transform($clydeShadow)
$g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 0, 0))), $clyde)
$clydeShadow.Translate(0, -2.5)
$clyde.Transform($clydeShadow)

$clydeBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.RectangleF(36, 42, 72, 62)),
    [System.Drawing.Color]::FromArgb(255, 255, 255),
    [System.Drawing.Color]::FromArgb(228, 233, 242),
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
)
$g.FillPath($clydeBrush, $clyde)
$g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1.2)), $clyde)

$eyeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0x40, 0x4E, 0xED))
$g.FillEllipse($eyeBrush, (New-Object System.Drawing.RectangleF(53, 68, 10, 14)))
$g.FillEllipse($eyeBrush, (New-Object System.Drawing.RectangleF(81, 68, 10, 14)))

$g.Dispose()
Save-IconPair $bmp "icons8_discord_new_72px"
$bmp.Dispose()
Write-Host "Discord Clyde 3D icon generated cleanly with 0 errors!"
