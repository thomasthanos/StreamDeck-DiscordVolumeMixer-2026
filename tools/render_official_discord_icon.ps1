Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, System.Drawing

$outDirs = @(
    "H:\Projects\ThomasThanos\StreamDeck-DiscordVolumeMixer-2026\dist\icons",
    "H:\Projects\ThomasThanos\StreamDeck-DiscordVolumeMixer-2026\bin\Release\cz.danol.discordmixer.sdPlugin\icons",
    "$env:APPDATA\Elgato\StreamDeck\Plugins\cz.danol.discordmixer.sdPlugin\icons"
)

function Render-OfficialDiscordIcon {
    $width = 144
    $height = 144

    $dv = New-Object System.Windows.Media.DrawingVisual
    $dc = $dv.RenderOpen()

    # 1. Drop shadow under squircle
    $shadowBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(90, 0, 0, 0))
    $dc.DrawRoundedRectangle($shadowBrush, $null, [System.Windows.Rect]::new(0, 4, 144, 144), 0.01, 0.01)

    # 2. Main Apple 3D Squircle Blurple Gradient
    $bgGrad = New-Object System.Windows.Media.LinearGradientBrush(
        [System.Windows.Media.Color]::FromRgb(0x6E, 0x7B, 0xFA),
        [System.Windows.Media.Color]::FromRgb(0x40, 0x4E, 0xED),
        [System.Windows.Point]::new(0, 0),
        [System.Windows.Point]::new(0, 1)
    )

    # 3. Inner Bevel / Hairline Rim Pen
    $rimGrad = New-Object System.Windows.Media.LinearGradientBrush(
        [System.Windows.Media.Color]::FromArgb(160, 255, 255, 255),
        [System.Windows.Media.Color]::FromArgb(30, 0, 0, 0),
        [System.Windows.Point]::new(0, 0),
        [System.Windows.Point]::new(0, 1)
    )
    $rimPen = New-Object System.Windows.Media.Pen($rimGrad, 1.6)

    $dc.DrawRoundedRectangle($bgGrad, $rimPen, [System.Windows.Rect]::new(0, 0, 144, 144), 0.01, 0.01)

    # 4. Top Glass Specular Shine
    $shineGrad = New-Object System.Windows.Media.LinearGradientBrush(
        [System.Windows.Media.Color]::FromArgb(60, 255, 255, 255),
        [System.Windows.Media.Color]::FromArgb(0, 255, 255, 255),
        [System.Windows.Point]::new(0, 0),
        [System.Windows.Point]::new(0, 1)
    )
    $dc.DrawRoundedRectangle($shineGrad, $null, [System.Windows.Rect]::new(6, 2, 132, 60), 0.01, 0.01)

    # 5. Exact Official Discord Clyde Logo Vector
    $clydeSvg = "M 80.5 15 C 74.3 12.1 67.7 10 60.7 8.9 C 60.6 9.1 60.4 9.4 60.3 9.7 C 52.9 8.6 45.4 8.6 38.1 9.7 C 38 9.4 37.8 9.1 37.7 8.9 C 30.7 10 24.1 12.1 17.9 15 C 8.2 29.5 5.5 43.6 6.8 57.5 C 13.3 62.3 19.6 65.2 25.8 67.1 C 27.3 65.1 28.6 62.9 29.7 60.6 C 27.4 59.8 25.3 58.7 23.3 57.3 C 23.9 56.9 24.4 56.5 24.9 56.1 C 37.1 61.8 50.4 61.8 62.4 56.1 C 63 56.5 63.5 56.9 64 57.3 C 62 58.7 59.9 59.8 57.6 60.6 C 58.8 62.9 60.1 65.1 61.5 67.1 C 67.7 65.2 74.1 62.3 80.6 57.5 C 82.2 41.5 77.8 27.6 80.5 15 Z M 31.7 48.9 C 28 48.9 24.9 45.5 24.9 41.3 C 24.9 37.1 27.9 33.7 31.7 33.7 C 35.5 33.7 38.6 37.1 38.5 41.3 C 38.5 45.5 35.5 48.9 31.7 48.9 Z M 56.6 48.9 C 52.9 48.9 49.8 45.5 49.8 41.3 C 49.8 37.1 52.8 33.7 56.6 33.7 C 60.4 33.7 63.5 37.1 63.4 41.3 C 63.4 45.5 60.4 48.9 56.6 48.9 Z"

    $rawGeom = [System.Windows.Media.Geometry]::Parse($clydeSvg)
    $bounds = $rawGeom.Bounds

    # Target Clyde size on 144x144 tile
    $targetWidth = 64.0
    $scale = $targetWidth / $bounds.Width
    $targetHeight = $bounds.Height * $scale

    $offsetX = (144.0 - $targetWidth) / 2.0 - ($bounds.X * $scale)
    $offsetY = (144.0 - $targetHeight) / 2.0 - ($bounds.Y * $scale) + 1.0

    $transGroup = New-Object System.Windows.Media.TransformGroup
    $transGroup.Children.Add([System.Windows.Media.ScaleTransform]::new($scale, $scale))
    $transGroup.Children.Add([System.Windows.Media.TranslateTransform]::new($offsetX, $offsetY))

    $clydeGeom = $rawGeom.Clone()
    $clydeGeom.Transform = $transGroup

    # Clyde Drop Shadow
    $shadowTransGroup = New-Object System.Windows.Media.TransformGroup
    $shadowTransGroup.Children.Add($transGroup)
    $shadowTransGroup.Children.Add([System.Windows.Media.TranslateTransform]::new(0, 3))
    
    $clydeShadowGeom = $rawGeom.Clone()
    $clydeShadowGeom.Transform = $shadowTransGroup
    $dc.DrawGeometry([System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(90, 0, 0, 0)), $null, $clydeShadowGeom)

    # Clyde 3D Pearl Body
    $clydeBodyBrush = New-Object System.Windows.Media.LinearGradientBrush(
        [System.Windows.Media.Color]::FromRgb(255, 255, 255),
        [System.Windows.Media.Color]::FromRgb(230, 235, 245),
        [System.Windows.Point]::new(0, 0),
        [System.Windows.Point]::new(0, 1)
    )
    $clydePen = New-Object System.Windows.Media.Pen(
        [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(180, 255, 255, 255)),
        1.2
    )
    $dc.DrawGeometry($clydeBodyBrush, $clydePen, $clydeGeom)

    $dc.Close()

    # Render 144x144 bitmap
    $rtb144 = New-Object System.Windows.Media.Imaging.RenderTargetBitmap(144, 144, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
    $rtb144.Render($dv)

    # Render 72x72 bitmap with anti-aliased scaling
    $dv72 = New-Object System.Windows.Media.DrawingVisual
    $dc72 = $dv72.RenderOpen()
    $dc72.PushTransform([System.Windows.Media.ScaleTransform]::new(0.5, 0.5))
    $dc72.DrawImage($rtb144, [System.Windows.Rect]::new(0, 0, 144, 144))
    $dc72.Close()

    $rtb72 = New-Object System.Windows.Media.Imaging.RenderTargetBitmap(72, 72, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
    $rtb72.Render($dv72)

    # Save to all target icon directories
    foreach ($dir in $outDirs) {
        $p2x = Join-Path $dir "icons8_discord_new_72px@2x.png"
        $p1x = Join-Path $dir "icons8_discord_new_72px.png"

        $encoder2x = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $encoder2x.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb144))
        $stream2x = [System.IO.File]::OpenWrite($p2x)
        $encoder2x.Save($stream2x)
        $stream2x.Dispose()

        $encoder1x = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $encoder1x.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb72))
        $stream1x = [System.IO.File]::OpenWrite($p1x)
        $encoder1x.Save($stream1x)
        $stream1x.Dispose()
    }

    Write-Host "Official Discord Clyde 3D Icon rendered perfectly in @2x (144px) and 1x (72px)!"
}

Render-OfficialDiscordIcon
