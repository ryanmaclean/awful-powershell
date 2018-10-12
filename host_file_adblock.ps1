# for line in file, add to list and set ip to 0.0.0.0
# https://stackoverflow.com/questions/2602460/powershell-to-manipulate-host-file
# https://stackoverflow.com/questions/33511772/read-file-line-by-line-in-powershell/33511982 
# get updates from https://github.com/StevenBlack/hosts
# Requires that you first install carbon powershell http://get-carbon.org/ for now...

Import-Module BitsTransfer

# Stop on errors
$ErrorActionPreference = "Stop"

$hostfileRemote = https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts
$hostfileLocal = "$PSScriptRoot\hosts.tmp"
$startTime = Get-Date
$regex = "/^\s*(#|$)/" # match blank lines or those that start with `#`

function Download-Hostfile {
    try {
        #Test-Path $hostfileLocal -PathType Leaf
        Start-BitsTransfer -Source $hostfileLocal -Destination $hostfileLocal
    }
    catch {
        Write-Output "Local temporary file named hosts.tmp exists"
    }
}

function Update-Hostfile {
    foreach($line in Get-Content $hostfileLocal) {
        if($line -match $regex){
            Set-HostsEntry -IPAddress 127.0.1.1 -HostName $line -Description "blacklisted"
        }
    }
}

function main {
    Download-Hostfile
    Update-Hostfile
    Write-Output "Time taken: $((Get-Date).Subtract($startTime).Seconds) second(s)"
}

main
