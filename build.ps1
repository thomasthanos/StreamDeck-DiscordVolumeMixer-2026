# StreamDeck Discord Volume Mixer - Automated Build & Deploy Script

$ErrorActionPreference = "Stop"
$releaseVersion = "2.0.7"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Building StreamDeck Discord Volume Mixer " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Setup Toolchain Paths
$qtRoot = "C:\Users\Thomas\Documents\Codex\2026-08-25\c-users-thomas-downloads-streamdeck-discordvolumemixer2\work\qt\6.8.3\mingw_64"
$qtBin = "C:\Users\Thomas\Documents\Codex\2026-08-25\c-users-thomas-downloads-streamdeck-discordvolumemixer2\work\qt\Tools\mingw1310_64\bin"
$cmakeBin = "C:\Users\Thomas\Documents\Codex\2026-08-25\c-users-thomas-downloads-streamdeck-discordvolumemixer2\work\qt\Tools\CMake_64\bin"

if (Test-Path $qtBin) { $env:PATH = "$qtBin;$cmakeBin;" + $env:PATH }

# 2. Configure (if build folder does not exist)
if (!(Test-Path "build\CMakeCache.txt")) {
    Write-Host "`n[1/3] Configuring CMake..." -ForegroundColor Yellow
    cmake -B build -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$qtRoot"
}

# 3. Compile
Write-Host "`n[2/3] Compiling C++ binary..." -ForegroundColor Yellow
cmake --build build -j8

# Sign the executable before packaging. A production release should set
# DVM_CODE_SIGNING_CERT_THUMBPRINT to a publicly trusted/WDAC-approved signer.
$defaultDevelopmentThumbprint = "EF02B8D0092AFBE08C4307158F60FAA78499028F"
$signingThumbprint = if ($env:DVM_CODE_SIGNING_CERT_THUMBPRINT) {
    $env:DVM_CODE_SIGNING_CERT_THUMBPRINT
} else {
    $defaultDevelopmentThumbprint
}
$signingCertificatePath = "Cert:\CurrentUser\My\$signingThumbprint"
$builtExecutable = "$PSScriptRoot\bin\Release\com.thomast.discordmixer.sdPlugin\bin\streamdeck-discordmixer.exe"

if ((Test-Path -LiteralPath $signingCertificatePath) -and (Test-Path -LiteralPath $builtExecutable)) {
    Write-Host "Signing plugin executable..." -ForegroundColor Yellow
    $signingCertificate = Get-Item -LiteralPath $signingCertificatePath
    if (!$signingCertificate.HasPrivateKey) {
        throw "Code-signing certificate has no accessible private key: $signingThumbprint"
    }

    $signature = Set-AuthenticodeSignature -LiteralPath $builtExecutable `
        -Certificate $signingCertificate -HashAlgorithm SHA256 -IncludeChain All
    if (!$signature.SignerCertificate -or $signature.SignerCertificate.Thumbprint -ne $signingThumbprint) {
        throw "Failed to apply the expected Authenticode signature."
    }

    Write-Host "Signed with certificate: $signingThumbprint ($($signature.Status))" -ForegroundColor Cyan
} else {
    Write-Host "[WARNING] Code-signing certificate not found; package will be unsigned." -ForegroundColor Yellow
}

# 4. Install & Deploy Qt runtime to bin/Release bundle
Write-Host "`n[3/3] Packaging plugin bundle & deploying Qt DLLs..." -ForegroundColor Yellow
cmake --install build

# 5. Create GitHub Release Package (.streamDeckPlugin & .zip) in release/
$sourceBundle = "$PSScriptRoot\bin\Release\com.thomast.discordmixer.sdPlugin"
$releaseDir = "$PSScriptRoot\release"
if (!(Test-Path $releaseDir)) { New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null }
$streamDeckPluginFile = "$releaseDir\com.thomast.discordmixer.streamDeckPlugin"
$zipReleaseFile = "$releaseDir\StreamDeck-DiscordVolumeMixer-v$releaseVersion-Windows-x64.zip"

if (Test-Path $streamDeckPluginFile) { Remove-Item $streamDeckPluginFile -Force }
if (Test-Path $zipReleaseFile) { Remove-Item $zipReleaseFile -Force }

Write-Host "`n[4/4] Creating official Elgato Marketplace Release package in release/..." -ForegroundColor Yellow
npx -y @elgato/cli pack "$sourceBundle" --output "$releaseDir" -f
Copy-Item "$streamDeckPluginFile" -Destination "$zipReleaseFile" -Force
Write-Host "Created: release\com.thomast.discordmixer.streamDeckPlugin" -ForegroundColor Cyan
Write-Host "Created: release\StreamDeck-DiscordVolumeMixer-v$releaseVersion-Windows-x64.zip" -ForegroundColor Cyan

# 6. Copy plugin bundle to Stream Deck AppData (for local testing)
$pluginsDir = "$env:APPDATA\Elgato\StreamDeck\Plugins"
$pluginDestination = Join-Path $pluginsDir "com.thomast.discordmixer.sdPlugin"
$streamDeckExecutable = Join-Path $env:ProgramFiles "Elgato\StreamDeck\StreamDeck.exe"

if (Test-Path $sourceBundle) {
    Write-Host "`nDeploying to Stream Deck AppData..." -ForegroundColor Green
    $streamDeckWasRunning = [bool](Get-Process "StreamDeck" -ErrorAction SilentlyContinue)
    try {
        if ($streamDeckWasRunning) {
            Write-Host "Temporarily stopping Stream Deck to release plugin files..." -ForegroundColor Yellow
            Stop-Process -Name "StreamDeck" -Force -ErrorAction Stop
        }

        Stop-Process -Name "streamdeck-discordmixer" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 750

        if (Test-Path -LiteralPath $pluginDestination) {
            Remove-Item -LiteralPath $pluginDestination -Recurse -Force
        }
        Copy-Item -LiteralPath $sourceBundle -Destination $pluginDestination -Recurse -Force

        Write-Host "`n=========================================" -ForegroundColor Green
        Write-Host " BUILD, RELEASE & DEPLOY COMPLETE!       " -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
    }
    catch {
        Write-Host "`n[ERROR] Live plugin deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
    finally {
        if ($streamDeckWasRunning -and (Test-Path -LiteralPath $streamDeckExecutable)) {
            Write-Host "Restarting Stream Deck..." -ForegroundColor Yellow
            Start-Process -FilePath $streamDeckExecutable -WindowStyle Hidden
        }
    }
}
