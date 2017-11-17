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

