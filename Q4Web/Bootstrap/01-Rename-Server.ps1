$countTagName = "WEB-$AppEnvironment-$AppGroupName-InstanceCount"

$tags = Get-EC2Tag -Filter @{ Name="resource-type"; Values="instance"}, @{ Name="key"; Values= $countTagName }
$countTag = New-Object Amazon.EC2.Model.Tag
$countTag.Key = $countTagName
$countTag.Value = "1"

if($tags) {
    Write-Host "Found $countTagName. Incrementing the value and updating existing instances."
    
    $countTag.Value = [int]$tags[0].Value + 1
    
    foreach($tag in $tags) {
      New-EC2Tag -Resource $tag.ResourceId -Tag $countTag
    }
} else {
  Write-Host "$countTagName not found, creating."
  New-EC2Tag -Resource $InstanceId -Tag $countTag
}

$countTagValue = $countTag.Value

Write-Host "Setting instance tag to $newName"
$newName = "WEB-$AppEnvironment-$AppGroupName$countTagValue"

$nameTag = New-Object Amazon.EC2.Model.Tag
$nameTag.Key = "Name"
$nameTag.Value = $newName
New-EC2Tag -Resource $InstanceId -Tag $nameTag

