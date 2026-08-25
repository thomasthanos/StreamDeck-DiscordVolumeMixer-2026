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

function Draw-Speaker([System.Drawing.Graphics]$g, $color) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddLine(30.0, 60.0, 50.0, 60.0)
    $path.AddLine(50.0, 60.0, 75.0, 40.0)
    $path.AddLine(75.0, 40.0, 75.0, 104.0)
    $path.AddLine(75.0, 104.0, 50.0, 84.0)
    $path.AddLine(50.0, 84.0, 30.0, 84.0)
    $path.CloseFigure()
    
    $brush = New-Object System.Drawing.SolidBrush($color)
    $g.FillPath($brush, $path)
    $g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1.2)), $path)
}

function Draw-Waves([System.Drawing.Graphics]$g, $color) {
    $pen = New-Object System.Drawing.Pen($color, 6.0)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    
    # Inner wave
    $g.DrawArc($pen, 85, 60, 20, 24, -60, 120)
    
    # Outer wave
    $pen2 = New-Object System.Drawing.Pen($color, 6.0)
    $pen2.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen2.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawArc($pen2, 85, 45, 40, 54, -60, 120)
}

# 1. No Audio (Muted Speaker)
$bmpNoAudio = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gNoAudio = [System.Drawing.Graphics]::FromImage($bmpNoAudio)
$gNoAudio.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

# Tile
Draw-AppleTile $gNoAudio 10.0 10.0 124.0 124.0 ([System.Drawing.Color]::FromArgb(0x3B, 0x3B, 0x3B)) ([System.Drawing.Color]::FromArgb(0x1E, 0x1E, 0x1E)) 30.0

# Clip graphics so the red line doesn't bleed out of the tile!
$clipPath = Create-RoundedRectPath 10.0 10.0 124.0 124.0 30.0
$gNoAudio.SetClip($clipPath)

# White Speaker
Draw-Speaker $gNoAudio ([System.Drawing.Color]::FromArgb(255, 255, 255))

# White Waves (muted)
$waveColor = [System.Drawing.Color]::FromArgb(160, 255, 255, 255)
$penW = New-Object System.Drawing.Pen($waveColor, 6.0)
$penW.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$penW.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$gNoAudio.DrawArc($penW, 85, 60, 20, 24, -60, 120)
$gNoAudio.DrawArc($penW, 85, 45, 40, 54, -60, 120)

# Red Strike Line (stays within clip)
$redPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0xFF, 0x3B, 0x30), 8.0)
$redPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$redPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$gNoAudio.DrawLine($redPen, 35.0, 109.0, 109.0, 35.0)

$gNoAudio.ResetClip()
$gNoAudio.Dispose()
Save-IconPair $bmpNoAudio "icons8_no_audio_72px"

# 2. Speaking Deco (Green Neon Overlay Ring)
# The old one might have had bad arcs or positioning. 
# This needs to be a transparent background with just a green ring.
$bmpDeco = New-Object System.Drawing.Bitmap(144, 144, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gDeco = [System.Drawing.Graphics]::FromImage($bmpDeco)
$gDeco.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gDeco.Clear([System.Drawing.Color]::Transparent)

# Green Neon Ring over the tile (Tile bounds are 10,10 to 134,134)
# Let's draw it exactly matching the tile's outer bounds, but as a neon stroke.
$ringPath = Create-RoundedRectPath 8.0 8.0 128.0 128.0 32.0

$neonBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 255, 100))
$neonPen = New-Object System.Drawing.Pen($neonBrush, 4.0)

$gDeco.DrawPath($neonPen, $ringPath)

$gDeco.Dispose()
Save-IconPair $bmpDeco "speaking_deco"

