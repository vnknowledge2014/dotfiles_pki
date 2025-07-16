# PowerShell script for dotfiles setup
# Requires Administrator privileges

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "Starting dotfiles setup..." -ForegroundColor Green

# 0. Install PKI certificates
Write-Host "Installing PKI certificates..." -ForegroundColor Yellow
$certsPath = Join-Path $PSScriptRoot "certs"
if (Test-Path $certsPath) {
    Get-ChildItem $certsPath -Include "*.cer", "*.crt", "*.pem" | ForEach-Object {
        $certFile = $_.FullName
        $certName = $_.Name
        try {
            Import-Certificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\Root
            Write-Host "Installed certificate: $certName" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install certificate: $certName - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Certs folder not found!" -ForegroundColor Red
}

# 1. Install fonts from fonts folder
Write-Host "Installing fonts..." -ForegroundColor Yellow
$fontsPath = Join-Path $PSScriptRoot "fonts"
if (Test-Path $fontsPath) {
    Get-ChildItem $fontsPath -Filter "*.zip" | ForEach-Object {
        $zipFile = $_.FullName
        $tempDir = Join-Path $env:TEMP $_.BaseName
        
        Write-Host "Extracting $($_.Name)..." -ForegroundColor Cyan
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
        
        # Install font files
        Get-ChildItem $tempDir -Recurse -Include "*.ttf", "*.otf" | ForEach-Object {
            $fontFile = $_.FullName
            $fontName = $_.Name
            $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
            $fontsFolder.CopyHere($fontFile, 0x10)
            Write-Host "Installed font: $fontName" -ForegroundColor Green
        }
        
        Remove-Item $tempDir -Recurse -Force
    }
} else {
    Write-Host "Fonts folder not found!" -ForegroundColor Red
}

# 2. Check, install and update WSL2
Write-Host "Checking WSL2..." -ForegroundColor Yellow
$wslStatus = wsl --status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing WSL2..." -ForegroundColor Cyan
    wsl --install --no-distribution
    Write-Host "WSL2 installed. Please restart your computer and run this script again." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "Updating WSL2..." -ForegroundColor Cyan
    wsl --update
}

# 3. Install Kali Linux for WSL2
Write-Host "Installing Kali Linux..." -ForegroundColor Yellow
$kaliInstalled = wsl -l -q | Select-String "kali-linux"
if (-not $kaliInstalled) {
    Write-Host "Installing Kali Linux distribution..." -ForegroundColor Cyan
    wsl --install -d kali-linux
} else {
    Write-Host "Kali Linux already installed." -ForegroundColor Green
}

# 4. Shutdown WSL and copy .wslconfig
Write-Host "Shutting down WSL..." -ForegroundColor Yellow
wsl --shutdown

Write-Host "Configuring WSL..." -ForegroundColor Yellow
$userProfile = $env:USERPROFILE
$wslConfigSource = Join-Path $PSScriptRoot "wsl\.wslconfig"
$defaultWslConfigPath = Join-Path $userProfile ".wslconfig"

Write-Host "Default path: $defaultWslConfigPath" -ForegroundColor Cyan
$wslConfigPath = Read-Host "Enter path for .wslconfig file (press Enter for default)"
if ([string]::IsNullOrWhiteSpace($wslConfigPath)) {
    $wslConfigPath = $defaultWslConfigPath
}

if (Test-Path $wslConfigSource) {
    Copy-Item $wslConfigSource $wslConfigPath -Force
    Write-Host "WSL config copied to: $wslConfigPath" -ForegroundColor Green
} else {
    Write-Host "Source .wslconfig not found!" -ForegroundColor Red
}

# 5. Start Kali Linux WSL2
Write-Host "Starting Kali Linux..." -ForegroundColor Yellow
wsl -d kali-linux -e echo "Kali Linux started"

# 6. Execute index.sh in Kali Linux
Write-Host "Executing index.sh in Kali Linux..." -ForegroundColor Yellow
$indexShPath = Join-Path $PSScriptRoot "index.sh"
if (Test-Path $indexShPath) {
    wsl -d kali-linux bash index.sh
    Write-Host "index.sh executed successfully!" -ForegroundColor Green
} else {
    Write-Host "index.sh not found!" -ForegroundColor Red
}

Write-Host "Setup completed!" -ForegroundColor Green