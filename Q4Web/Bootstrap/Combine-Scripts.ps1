param(
    [string] $AWSAccessKey = $null,
    
    [string] $AWSSecretKey = $null,

    [string] $S3Bucket = $null
)

Import-Module AWSPowerShell

$uploadToS3 = ![string]::IsNullOrEmpty($AWSAccessKey) -and ![string]::IsNullOrEmpty($AWSSecretKey) -and ![string]::IsNullOrEmpty($S3Bucket)
$outputScript = "Bootstrap.ps1"

$invocation = (Get-Variable MyInvocation).Value
$scriptBasePath = Split-Path $invocation.MyCommand.Path

$combinedScriptExists = Test-Path "$scriptBasePath\$outputScript"
if($combinedScriptExists) {
    Remove-Item "$scriptBasePath\$outputScript" -Force
}

New-Item -Path "$scriptBasePath\$outputScript" -ItemType file | Out-Null

$exclude = @("*Combined.ps1", "Combine-Scripts.ps1", "Bootstrap.ps1", "Deploy-Project-ExistingRelease.ps1")
$FileList = Get-ChildItem -Path $scriptBasePath -Exclude $exclude
foreach ($File in $FileList) 
{
    Write-Host "Adding contents of $($File.Name) to bootstrap script"
    $File | Get-Content | Add-Content -path ".\$outputScript"
}

if($uploadToS3) {
    Set-AWSCredentials -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey
    Write-Host "`nUploading to $S3Bucket S3 bucket"
    Write-S3Object -BucketName $S3Bucket -Key "Bootstrap.ps1" -File ".\$outputScript"
}