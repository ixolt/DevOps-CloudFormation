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
        $webClient = new-object Net.WebClient
        $instanceId = $Machine
        $octopusProject = $projectName
        $scriptDir = $env:TEMP
        Set-location $scriptDir

        write-host "Get latest release for project $octopusProject and environment $Environment"
        Set-Alias Octo "$scriptDir\Octo.exe" -scope Script
    
        $release = (Octo list-latestdeployments --project="$octopusProject" `
        --server="$octopusServerUrl" `
        --apikey="$yourApiKey" `
        --environment="$Environment" | `
        ?{$_.contains("Version:") } | select-object -first 1)
    
        if (!$release) {
            write-warning "Current release for $octopusProject not found"
            return
        }   
 
        write-host "Pull current release $release"
    
        $release = $release.Replace("Version: ","")
        $release = $release.Replace("`"", "")
        $release = $release.Trim()
    
        Octo deploy-release --project="$octopusProject" `
        --server="$octopusServerUrl" `
        --apiKey="$yourApiKey" `
        --version="$release" `
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