# Set the funtion of your caps lock key to control because it's where it should be :)
# Tested in Powershell 5.1 on Windows 10 
# Requires a reboot in order to take effect 
# Created using the http://joshua.poehls.me/powershell-script-boilerplate/

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$scriptDir = Split-Path -LiteralPath $PSCommandPath
$startingLoc = Get-Location
Set-Location $scriptDir
$startingDir = [System.Environment]::CurrentDirectory
[System.Environment]::CurrentDirectory = $scriptDir

# The real magic is here, we're essentially running a registry insert
# Taken from https://superuser.com/a/997448
$hexified = "00,00,00,00,00,00,00,00,02,00,00,00,1d,00,3a,00,00,00,00,00".Split(',') | % { "0x$_"};
$kbLayout = 'HKLM:\System\CurrentControlSet\Control\Keyboard Layout';

try {
  New-ItemProperty -Path $kbLayout -Name "Scancode Map" -PropertyType Binary -Value ([byte[]]$hexified);
}

finally {
  Write-Output "Done. Elapsed time: $($stopwatch.Elapsed)"
  Write-Output "Powershell verion:"
  $PSVersionTable.PSVersion
  Set-Location $startingLoc
  [System.Environment]::CurrentDirectory = $startingDir
}
