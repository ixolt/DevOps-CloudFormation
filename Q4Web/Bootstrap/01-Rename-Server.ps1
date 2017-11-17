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

