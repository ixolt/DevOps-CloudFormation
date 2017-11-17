param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $OctopusEnvironment="Staging",

    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $OctopusMachineRole="web-server",

    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $ServerConfigurationProject="Configure Q4Web Server",

    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [bool]
    $RunServerConfigurationProject=$true,

    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $InstanceId="DEV", 
    
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $AppEnvironment="DEV", 
  
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $AppGroupName    
)

$countTagName = "Q4WEB-$AppEnvironment-$AppGroupName-InstanceCount"

$tags = Get-EC2Tag -Filter @{ Name="resource-type"; Values="instance"}, @{ Name="key"; Values= $countTagName }
$countTag = New-Object Amazon.EC2.Model.Tag
$countTag.Key = $countTagName
$countTag.Value = "1"

if($tags) {
    $countTag.Value = [int]$tags[0].Value + 1
} else {
   New-EC2Tag -Resource $InstanceId -Tag $countTag
}

foreach($tag in $tags) {
   New-EC2Tag -Resource $tag.ResourceId -Tag $countTag
}
$countTagValue = $countTag.Value

$newName = "Q4WEB-$AppEnvironment-$AppGroupName-$countTagValue"

$nameTag = New-Object Amazon.EC2.Model.Tag
$nameTag.Key = "Name"
$nameTag.Value = $newName
New-EC2Tag -Resource $InstanceId -Tag $nameTag

function Install-Tentacle() {
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $MachineRole,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $ComputerName,

        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [boolean]
        $deployProjects=$False
    )

    # If for whatever reason this doesn't work, check this file:
    Start-Transcript -path "C:\TentacleInstallLog.txt" -append

    $tentacleDownloadPath = "http://octopusdeploy.com/downloads/latest/OctopusTentacle64"
    $octoDownloadPath = "http://octopusdeploy.com/downloads/latest/OctopusTentacle64"
    $yourApiKey = "API-GN2MTM4QMVDJVPDBQTOLEUADZN4"
    $octopusServerUrl = "https://deploy.q4web.com:8443/"
    $registerInEnvironments = $Environment
    $registerInRoles = $MachineRole
    $octopusServerThumbprint = "CF696C764FD6D474108055B10757DEF38ACF2CFC"
    $tentacleListenPort = "10943"
    $tentacleHomeDirectory = "$env:SystemDrive:\Octopus"
    $tentacleAppDirectory = "$env:SystemDrive:\Octopus\Applications"
    $tentacleConfigFile = "$env:SystemDrive\Octopus\Tentacle.config"

    function Download-File 
    {
      param (
        [string]$url,
        [string]$saveAs
      )
  
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
  
      Write-Host "Downloading $url to $saveAs"
      $downloader = new-object System.Net.WebClient
      $downloader.DownloadFile($url, $saveAs)
    }

    # We're going to use Tentacle in Listening mode, so we need to tell Octopus what its IP address is. Since my Octopus server
    # is hosted somewhere else, I need to know the public-facing IP address. 
    function Get-MyPublicIPAddress
    {
      Write-Host "Getting public IP address"
      $downloader = new-object System.Net.WebClient
      $ip = $downloader.DownloadString("http://ifconfig.me/ip")
      return $ip
    }

    function Expand-ZIPFile($file, $destination)
    {
        $shell = new-object -com shell.application
        $zip = $shell.NameSpace($file)
        foreach($item in $zip.items())
        {
            $shell.Namespace($destination).copyhere($item)
        }
    }

    function Install-OctopusTentacle 
    {
      param (
         [Parameter(Mandatory=$True)]
         [string]$apiKey,
         [Parameter(Mandatory=$True)]
         [System.Uri]$octopusServerUrl,
         [Parameter(Mandatory=$True)]
         [string]$environment,
         [Parameter(Mandatory=$True)]
         [string]$role
      )

      Write-Output "Beginning Tentacle installation"

      Write-Output "Downloading latest Octopus Tentacle MSI..."

      $tentaclePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\Tentacle.msi")
      if ((test-path $tentaclePath) -ne $true) {
        Download-File $tentacleDownloadPath $tentaclePath
      }
  
      Write-Output "Installing MSI"
      $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i Tentacle.msi /quiet" -Wait -Passthru).ExitCode
      Write-Output "Tentacle MSI installer returned exit code $msiExitCode"
      if ($msiExitCode -ne 0) {
        throw "Installation aborted"
      }

      Write-Output "Open port $tentacleListenPort on Windows Firewall"
      & netsh.exe advfirewall firewall add rule "name=Octopus Deploy Tentacle" dir=in action=allow protocol=TCP localport=10933
      if ($lastExitCode -ne 0) {
        throw "Installation failed when modifying firewall rules"
      }
 
      Write-Output "Configuring and registering Tentacle"
      
  
      cd "${env:ProgramFiles}\Octopus Deploy\Tentacle"

      & .\tentacle.exe create-instance --instance "Tentacle" --config $tentacleConfigFile --console | Write-Host
      if ($lastExitCode -ne 0) {
        throw "Installation failed on create-instance"
      }
      & .\tentacle.exe new-certificate --instance "Tentacle" --if-blank --console | Write-Host
      if ($lastExitCode -ne 0) {
        throw "Installation failed on creating new certificate"
      }
      & .\tentacle.exe configure --instance "Tentacle" --reset-trust | Write-Host
      if ($lastExitCode -ne 0) {
        throw "Installation failed on resetting trust"
      }
      & .\tentacle.exe configure --instance "Tentacle" 	--home $tentacleHomeDirectory --app $tentacleAppDirectory --port "10933" --noListen "True" --console | Write-Host
      if ($lastExitCode -ne 0) {
        throw "Installation failed on configure"
      }

      Write-Output "Server Url: $octopusServerUrl Name: $ComputerName API Key: $apiKey Environment: $environment Role: $role"
      & .\tentacle.exe register-with --instance "Tentacle" --server $octopusServerUrl --name $ComputerName --apiKey $apiKey --comms-style "TentacleActive" --server-comms-port "10943" --force --environment $environment --role $role --console | Write-Host
      if ($lastExitCode -ne 0) {
        throw "Installation failed on register-with"
      }
 
      & .\tentacle.exe service --instance "Tentacle" --install --start --console | Write-Host
      if ($lastExitCode -ne 0) {
        throw "Installation failed on service install"
      }
  
      & .\tentacle.exe service --instance "Tentacle" --stop --console | Write-Host
      & .\tentacle.exe service --instance "Tentacle" --start --console | Write-Host
 
      Write-Output "Tentacle commands complete"
    }

    Install-OctopusTentacle -apikey $yourApiKey -octopusServerUrl $octopusServerUrl -environment $registerInEnvironments -role $registerInRoles
}

function Deploy-Project() {
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $Project,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $Machine
    )

    # If for whatever reason this doesn't work, check this file:
    Start-Transcript -path "C:\DeployProjectLog.txt" -append

    $octoDownloadPath = "https://download.octopusdeploy.com/octopus-tools/3.5.4/OctopusTools.3.5.4.zip"
    $yourApiKey = "API-GN2MTM4QMVDJVPDBQTOLEUADZN4"
    $octopusServerUrl = "https://deploy.q4web.com:8443/"

    function Download-File 
    {
      param (
        [string]$url,
        [string]$saveAs
      )
  
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
  
      Write-Host "Downloading $url to $saveAs"
      $downloader = new-object System.Net.WebClient
      $downloader.DownloadFile($url, $saveAs)
    }

    function Expand-ZIPFile($file, $destination)
    {
        $shell = new-object -com shell.application
        $zip = $shell.NameSpace($file)
        foreach($item in $zip.items())
        {
            $shell.Namespace($destination).copyhere($item)
        }
    }

    Download-File $octoDownloadPath "$env:TEMP\OctopusTools.zip"
    Expand-ZIPFile "$env:TEMP\OctopusTools.zip" "$env:TEMP\"

    function DeployProject($projectName)
    {
        $instanceId = $Machine
        $octopusProject = $projectName
        $scriptDir = $env:TEMP
        
        Set-location $scriptDir

        Write-Host "Deploying $octopusProject to $Machine in $Environment"

        Set-Alias Octo "$scriptDir\Octo.exe" -scope Script
    
        Octo create-release --project="$octopusProject" `
        --server="$octopusServerUrl" `
        --apiKey="$yourApiKey" `
        --specificmachines="$instanceId" `
        --deployto="$Environment" `
        --waitfordeployment `
        --deploymenttimeout="015:00:00"
    }	
 
    function Cleanup 
    {
        Set-location $env:TEMP	
	
        Remove-Item "Octo.exe"
        Remove-Item "Octo.exe.config"
    }
 
    DeployProject $Project

    Cleanup
}

function Add-HostsEntry() {

    param(
        [Parameter(Mandatory=$true)]
        [string]
        $IPAddress,

        [Parameter(Mandatory=$true)]
        [string]
        $HostName
    )

    $hostsFile = "$env:windir\System32\drivers\etc\hosts"

    # check if the entry exists
    $lines = Get-Content -Path $hostsFile
    $outLines = New-Object 'Collections.ArrayList'

    foreach($line in $lines) {
        if($line.Contains($ipAddress) -and $line.Contains($hostName)) {
            continue
        } else {
            [void] $outLines.Add($line)
        }
    }

    # Add new entry
    $newLine = "`n{0}`t`t{1}" -f $IPAddress, $HostName

    [void] $outLines.Add($newLine)
    $outLines = $outLines.Trim()

    $outLines | Out-File -Encoding ascii $hostsFile

    $message = "IP Address: {0} and HostName: {1}" -f $IPAddress, $HostName
    Write-Host "$message added to hosts file"
}

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
