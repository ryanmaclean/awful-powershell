<#
.SYNOPSIS
Microsoft Terminal Install Script

.DESCRIPTION
This script will attempt to install the latest Microsoft Terminal release
from GitHub. It will try to use the Windows Store version by default, but can be
adapted to skip this and use a download then double unzip workflow instead.
It will otherwise attempt this method should the Windows Store not be present in 
order to accomodate LTS releases. 

.EXAMPLE
Usage "./install_latest_win_term.ps1"

.NOTES
Adapted from https://adamtheautomator.com/powershell-json
This will download and expand in the current directory unles $pwd is modified 
in the exapand-msixbundle section
#>

## Import Appx, we need this to perform the installation at the end
## Note some fun with Powershell 7 on Windows 10 as of 04/2022 so "-usewindowspowershell" here
## Should not be required once https://github.com/PowerShell/PowerShell/issues/13138 is fixed
Import-Module Appx -usewindowspowershell

## Prerequisites
## Repository settings - address these if you want to fork and make your own GitHub latest release downloader! 
$OWNER = "microsoft"
$REPO = "terminal"

## OSVERSION can be Win10 or Win11
## If for some reason we can no longer get the Major version this way, we can use one of the two strings for OSVERSION
$MAJOR =[System.Environment]::OSVersion.Version.Major
$OSVERSION = "Win$MAJOR"

## Architecture, can be "x64", "x86" or "ARM64"
$ARCH = "x64"

## Using Invoke-WebRequest, you can adapt this to any repo with company and repo names
$webData = ConvertFrom-JSON (Invoke-WebRequest -uri "https://api.github.com/repos/$OWNER/$REPO/releases/latest")

## The release download information is stored in the "assets" section of the data
## Note that this can contain many results, so we need to be judicious in our query, and this part is a bit brittle as a result
$assets = $webData.assets

## This pipeline is used to filter the assets object to find the release version we want
## Asset URL examples: https://github.com/microsoft/terminal/releases/download/v1.12.10982.0/Microsoft.WindowsTerminal_Win10_1.12.10982.0_8wekyb3d8bbwe.msixbundle
## and https://github.com/microsoft/terminal/releases/download/v1.12.10982.0/Microsoft.WindowsTerminal_Win10_1.12.10982.0_8wekyb3d8bbwe.msixbundle_Windows10_PreinstallKit.zip
## Because of this, we look for asset URLs that DON'T have PreinstallKit in them. 
$asset = $assets | where-object { $_.name -match "_$OSVERSION" -and $_.name -notmatch "PreinstallKit"}

## See if we have the Microsoft Terminal Installed
Function get-terminal-install-status {
    if (Get-AppxPackage -Name Microsoft.WindowsTerminal) {
        Write-Output "Windows Terminal is installed, will attempt to upgrade"
    }
    else {
        Write-Output "Windows Terminal is not installed, will attempt to install"
    }
}

## Install the msixbundle directly from the URL
function install-terminal {
    ## Paste out the values so we know what we'll install 
    write-output "Installing $($asset.name)"
    write-output "From: $asset.browser_download_url" 

    if (Get-AppxPackage -Name Microsoft.WindowsStore) {
        Write-Output "Windows Store is installed, attempting this method"
        if (add-appxpackage -Path $asset.browser_download_url){
            Write-Output "Installed via Windows Store!"
        }
        else {
            Write-Output "Failed, is the Microsoft Terminal still open?"
        }
    }

    else {
        Write-Output "Microsoft Store not installed, downloading and installing Microsoft Terminal"
        expand-msixbundle
    }
}

function expand-msixbundle {
    Write-Output "Downloading to current directory"
    Invoke-WebRequest $asset.browser_download_url -OutFile "$pwd\$($asset.name)"
    Write-Output "Expanding in current directory"
    if (Expand-Archive "$pwd\$($asset.name)" -DestinationPath $pwd) {
        Write-Output "Extracted msixbundle file"
    }
    else {
        Write-Output "Files exist, attempting to overwrite using -Force flag"
        Expand-Archive "$pwd\$($asset.name)" -DestinationPath $pwd -Force
    }
    
    ## Using ` here for multi-line command, but feel free to make it a one-liner! 
    $Msix = Get-ChildItem $pwd `
    | Where-Object { $_.Extension -eq ".msix" } `
    | Where-Object { $_.Name.Contains($ARCH) }

    if (Expand-Archive $Msix.FullName -DestinationPath $pwd) {
        Write-Output "Extracted files from msix"
    }
    else {
        Write-Output "Files exist, attempting to overwrite using -Force flag"
        Expand-Archive $Msix.FullName -DestinationPath $pwd -Force
    }
    Write-Output "Files expanded, run WindowsTerminal.exe in this directory to test!"
    .\WindowsTerminal.exe
}

get-terminal-install-status
install-terminal
