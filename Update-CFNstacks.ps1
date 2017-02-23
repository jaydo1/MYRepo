$StackName = Get-Content C:\StackName.txt
$intanceSize = "r3.xlarge"

Foreach($Stack in $StackName){  

Update-CFNStack -StackName $Stack -UsePreviousTemplate $true  -Parameter @( @{ parameterKey="InstanceType";ParameterValue="$intanceSize"})`
-Capabilities "CAPABILITY_IAM"
}