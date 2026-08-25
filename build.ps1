# StreamDeck Discord Volume Mixer - Automated Build & Deploy Script

$ErrorActionPreference = "Stop"

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

# 4. Install & Deploy Qt runtime to bin/Release bundle
Write-Host "`n[3/3] Packaging plugin bundle & deploying Qt DLLs..." -ForegroundColor Yellow
cmake --install build

# 5. Create GitHub Release Package (.streamDeckPlugin & .zip) in release/
$sourceBundle = "$PSScriptRoot\bin\Release\com.thomast.discordmixer.sdPlugin"
$releaseDir = "$PSScriptRoot\release"
if (!(Test-Path $releaseDir)) { New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null }
$streamDeckPluginFile = "$releaseDir\com.thomast.discordmixer.streamDeckPlugin"
$zipReleaseFile = "$releaseDir\StreamDeck-DiscordVolumeMixer-v2.0.3-Windows-x64.zip"

if (Test-Path $streamDeckPluginFile) { Remove-Item $streamDeckPluginFile -Force }
if (Test-Path $zipReleaseFile) { Remove-Item $zipReleaseFile -Force }

Write-Host "`n[4/4] Creating official Elgato Marketplace Release package in release/..." -ForegroundColor Yellow
npx -y @elgato/cli pack "$sourceBundle" --output "$releaseDir" -f
Copy-Item "$streamDeckPluginFile" -Destination "$zipReleaseFile" -Force
Write-Host "Created: release\com.thomast.discordmixer.streamDeckPlugin" -ForegroundColor Cyan
Write-Host "Created: release\StreamDeck-DiscordVolumeMixer-v2.0.3-Windows-x64.zip" -ForegroundColor Cyan

# 6. Copy plugin bundle to Stream Deck AppData (for local testing)
$pluginsDir = "$env:APPDATA\Elgato\StreamDeck\Plugins"

if (Test-Path $sourceBundle) {
    Write-Host "`nDeploying to Stream Deck AppData..." -ForegroundColor Green
    try {
        # Check if plugin binary is running
        $pluginProc = Get-Process "streamdeck-discordmixer" -ErrorAction SilentlyContinue
        if ($pluginProc) {
            Write-Host "Stopping running plugin process to update files..." -ForegroundColor Yellow
            Stop-Process -Name "streamdeck-discordmixer" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        }
        Copy-Item -Path "$sourceBundle" -Destination "$pluginsDir\" -Recurse -Force
        Write-Host "`n=========================================" -ForegroundColor Green
        Write-Host " BUILD, RELEASE & DEPLOY COMPLETE!       " -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
    }
    catch {
        Write-Host "`n[NOTE] Could not overwrite files in AppData because Stream Deck is currently running." -ForegroundColor Yellow
        Write-Host "Close the Stream Deck application and run ./build.ps1 again to update the live plugin." -ForegroundColor Yellow
        Write-Host "`nThe compiled bundle is ready at: bin/Release/com.thomasthanos.discordmixer.sdPlugin" -ForegroundColor Green
        Write-Host "The GitHub Release files are ready at: release/" -ForegroundColor Green
    }
}
