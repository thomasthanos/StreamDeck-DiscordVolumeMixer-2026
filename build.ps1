# StreamDeck Discord Volume Mixer - Automated Build & Deploy Script

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Building StreamDeck Discord Volume Mixer " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Setup Toolchain Paths
$qtBin = "C:\Users\Thomas\Documents\Codex\2026-08-25\c-users-thomas-downloads-streamdeck-discordvolumemixer2\work\qt\Tools\mingw1310_64\bin"
$cmakeBin = "C:\Users\Thomas\Documents\Codex\2026-08-25\c-users-thomas-downloads-streamdeck-discordvolumemixer2\work\qt\Tools\CMake_64\bin"

if (Test-Path $qtBin) { $env:PATH = "$qtBin;$cmakeBin;" + $env:PATH }

# 2. Configure (if build folder does not exist)
if (!(Test-Path "build\CMakeCache.txt")) {
    Write-Host "`n[1/3] Configuring CMake..." -ForegroundColor Yellow
    cmake -B build -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
}

# 3. Compile
Write-Host "`n[2/3] Compiling C++ binary..." -ForegroundColor Yellow
cmake --build build -j8

# 4. Install & Deploy Qt runtime to bin/Release bundle
Write-Host "`n[3/3] Packaging plugin bundle & deploying Qt DLLs..." -ForegroundColor Yellow
cmake --install build

# 5. Copy plugin bundle to Stream Deck AppData
$sourceBundle = "$PSScriptRoot\bin\Release\cz.danol.discordmixer.sdPlugin"
$targetAppData = "$env:APPDATA\Elgato\StreamDeck\Plugins\cz.danol.discordmixer.sdPlugin"

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
        Copy-Item -Path "$sourceBundle" -Destination "$env:APPDATA\Elgato\StreamDeck\Plugins\" -Recurse -Force
        Write-Host "`n=========================================" -ForegroundColor Green
        Write-Host " BUILD & DEPLOY COMPLETE!                " -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
    }
    catch {
        Write-Host "`n[NOTE] Could not overwrite files in AppData because Stream Deck is currently running." -ForegroundColor Yellow
        Write-Host "Close the Stream Deck application and run ./build.ps1 again to update the live plugin." -ForegroundColor Yellow
        Write-Host "`nThe compiled bundle is ready at: bin/Release/cz.danol.discordmixer.sdPlugin" -ForegroundColor Green
    }
}
