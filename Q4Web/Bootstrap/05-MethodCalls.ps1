
Start-Transcript -Path "C:\Bootstrap_log.txt" -Append

$invocation = (Get-Variable MyInvocation).Value
$bootstrapPath = Split-Path $invocation.MyCommand.Path

Write-Host "`n"
Write-Host "Starting process of bootstrapping this machine"
Write-Host "`n"

# Set the powershell execution policy
Write-Host "`n"
Write-Host "Setting powershell execution policy to 'Unrestricted'"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted

Write-Host "`n"
Write-Host "Adding deploy.q4web.com to hosts file"
Add-HostsEntry -IPAddress "206.223.161.250" -HostName "deploy.q4web.com"

Set-Location $bootstrapPath

$tentacleExists = Get-Service | Where-Object ($_.Name -eq "OctopusDeploy Tentacle")
if(!$tentacleExists) {
    Write-Host "`n"
    Write-Host "Installing Octopus Tentacle"
    Install-Tentacle -Environment $OctopusEnvironment -MachineRole $OctopusMachineRole -ComputerName $newName
}

if($RunServerConfigurationProject) {
    Set-Location $bootstrapPath

    Write-Host "Waiting a minute before triggering 'Configure Web Server' deployment"
    Start-Sleep -Seconds 60

    Write-Host "`n"
    Write-Host "Calling Octopus server to deploy 'Configure Web Server'"
    Deploy-Project -Project $ServerConfigurationProject -Environment $OctopusEnvironment -Machine $newName
}

Rename-Computer -ComputerName $newName -Force

Write-Host "`n"
Write-Host "Bootstrapping complete!" -ForegroundColor Green
Write-Host "`n"

Exit 0