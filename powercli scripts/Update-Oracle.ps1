<#
.SYNOPSIS 
 Script to copy Oracle scripts across to all VC's 
.DESCRIPTION
 Script first asks for local admin credential then loops though server listed in VCname.txt then enters into a PSsesssion and runs SQLplus.bat 
.Paramaters
 None
.Example 
 None
.Disclaimer
 There is very little error handling in this script
.Version Change NOtes
1.0
#>

$cred = Get-Credential
$server_name = Get-Content C:\Temp\VCnames.txt
$command = {cmd.exe /c "C:\temp\SQLplus.bat"}

Foreach($server in $server_name) {
Copy-Item -path "C:\temp\resetpassword.txt" -Destination "\\$server\c$\temp"
Copy-Item -path "C:\temp\SQLplus.bat" -Destination "\\$server\c$\temp"
Enter-PSSession -ComputerName $server -Credential $cred

invoke-command -Scriptblock {$command}

Write-Host $server

Exit-PSSession
} 