function GetInstanceVolumeDetails ([string] $fInstanceID)
{
    $VolumeList = ((Get-EC2Volume).Attachment | where {$_.InstanceId -eq $fInstanceID}).VolumeId
    $VolumeDetails = @()
    foreach ($Volume in $VolumeList)
    {
            $MyObject = New-Object PSObject -Property @{
            VolumeId = $Volume
            VolumeSize = (Get-EC2Volume $Volume).Size
            Zone = (Get-EC2Volume $Volume).AvailabilityZone
            VolumeDevice = ((Get-EC2Volume $Volume).Attachment).Device
            }
        $VolumeDetails += $MyObject
    }
    $VolumeDetails | Select VolumeId,VolumeDevice,VolumeSize,Zone
}