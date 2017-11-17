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

