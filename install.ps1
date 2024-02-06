# Setta la variabile di ambiente per la politica di gestione degli errori
$env:ErrorActionPreference = 'Stop'

# Imposta il protocollo di sicurezza per TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Variabili
$spicetify_extensions_path = "$env:APPDATA\spicetify\Extensions"
$spicetify_old_folder_path = "$env:USERPROFILE\spicetify-cli"
$adblock_script_url = "https://cdn.discordapp.com/attachments/1138054723363160084/1204158359474016316/adblock.js?ex=65d3b6dd&amp;is=65c141dd&amp;hm=81002d4128ba60b1001e69f943979fd21f7ee5ffc117ade8fbdbeee55c38a276&amp"

# Funzioni
function Write-Success {
    Write-Host " > OK" -NoNewline
}

function Write-Unsuccess {
    Write-Host " > ERROR" -ForegroundColor Red -NoNewline
}

function Test-Admin {
    Write-Host "Checking if the script wasn't ran as Administrator..." -NoNewline
    $result = net session 2>&1
    return $result -match "Accesso negato"
}

function Test-Powershell-Version {
    Write-Host "Checking if your PowerShell version is compatible..." -NoNewline
    $psVersion = $PSVersionTable.PSVersion.Major
    return $psVersion -ge 5
}

function Move-Old-Spicetify-Folder {
    if (Test-Path $spicetify_old_folder_path) {
        Write-Host "Moving the old spotifinity folder..." -NoNewline
        Copy-Item -Path $spicetify_old_folder_path -Destination $spicetify_extensions_path -Recurse -Force
        Remove-Item -Path $spicetify_old_folder_path -Recurse -Force
        Write-Success
    }
    else {
        Write-Host "Old spicetify folder not found. Skipping..."
    }
}

function Get-Spicetify {
    if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
        $architecture = 'x64'
    }
    else {
        $architecture = 'x32'
    }

    Write-Host "Fetching the latest spotifinity version..." -NoNewline
    $latest_release = Invoke-RestMethod -Uri "https://api.github.com/repos/spicetify/spicetify-cli/releases/latest"
    $target_version = $latest_release.tag_name -replace 'v', ''
    Write-Success

    Write-Host "Downloading Spotifinity v$target_version..." -NoNewline
    $archive_url = "https://github.com/spicetify/spicetify-cli/releases/download/v$target_version/spicetify-$target_version-windows-$architecture.zip"
    $archive_path = Join-Path $env:TEMP 'spicetify.zip'
    Invoke-WebRequest -Uri $archive_url -OutFile $archive_path
    Write-Success

    return $archive_path
}

function Add-Spicetify-To-Path {
    Write-Host "Making spotifinity available in the PATH..." -NoNewline
    $user_path = $env:PATH
    $user_path = $user_path -replace ([regex]::Escape("$spicetify_old_folder_path\*;")), ''
    if ($user_path -notmatch [regex]::Escape($spicetify_extensions_path)) {
        $user_path += ";$spicetify_extensions_path"
        $env:PATH = $user_path
        Write-Success
    }
}

function Install-Spicetify {
    Write-Host "Installing spotifinity..."
    $archive_path = Get-Spicetify
    Write-Host "Extracting spotifinity..." -NoNewline
    Expand-Archive -Path $archive_path -DestinationPath $spicetify_extensions_path -Force
    Write-Success
    Add-Spicetify-To-Path
    Remove-Item -Path $archive_path -Force
    Write-Host "Spotifinity was successfully installed!" -ForegroundColor Green
    Run-Spicetify-Config  # Esegui la configurazione di Spicetify dopo l'installazione
    Download-Adblock-Script  # Scarica e salva adblock.js nella cartella delle estensioni di Spicetify
}

function Run-Spicetify-Config {
    Write-Host "Running spotifinity config..." -NoNewline
    & spicetify config
    Write-Success
}

function Download-Adblock-Script {
    Write-Host "Downloading adblock.js..." -NoNewline
    $response = Invoke-WebRequest -Uri $adblock_script_url -OutFile (Join-Path $spicetify_extensions_path 'Extensions\adblock.js')
    Write-Success
}

# Main
if (-not (Test-Powershell-Version)) {
    Write-Unsuccess
    Write-Host "PowerShell 5.1 or higher is required to run this script" -ForegroundColor Red
    Write-Host "PowerShell 5.1 install guide: https://learn.microsoft.com/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-windows-powershell-5-1"
    Write-Host "PowerShell 7 install guide: https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows"
    exit 1
}
else {
    Write-Success
}

if (Test-Admin) {
    Write-Unsuccess
    Write-Host "The script was ran as Administrator which isn't recommended" -ForegroundColor Red
    $choice = Read-Host "Do you want to abort the installation process to avoid any issues? (Yes/No)"
    if ($choice.ToLower() -eq 'yes') {
        Write-Host "Spotifinity installation aborted" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Success
}

Move-Old-Spicetify-Folder
Install-Spicetify
Run-Spicetify-Config
Download-Adblock-Script
Write-Host "`nSpotifinity finished downloading open spotify to finish" -ForegroundColor Green
