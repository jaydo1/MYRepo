Set-DefaultAWSRegion -Region ap-southeast-2 
$Instances = (Get-EC2Instance).instances 
$VPCS = Get-EC2Vpc 
foreach ($VPC in $VPCS) {
    $Instances | Where-Object {$_.VpcId -eq $VPC.VpcId} | foreach {
      $InstanceName =  ($_.Tags | Where-Object {$_.Key -eq 'Name'}).Value
Write-Host 'InstanceName: $InstanceName' 
       if ($InstanceName -like 'XXXXXX') { 
           New-Object -TypeName PSObject -Property @{ 
               'VpcId' = $_.VpcId 
               'VPCName' = ($VPC.Tags | Where-Object {$_.Key -eq 'Name'}).Value 
               'InstanceId' = $_.InstanceId
               'InstanceName' = ($_.Tags | Where-Object {$_.Key -eq 'Name'}).Value 
               'LaunchTime' = $_.LaunchTime 
               'State' = $_.State.Name 
               'KeyName' = $_.KeyName  
           } 
            Stop-EC2Instance -Instance $_.InstanceId 
       } 
   } 
} 
