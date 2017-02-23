$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Unrestricted c:\powershell\stop-all-instances.ps1"  
$trigger =  New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 6PM 
Unregister-ScheduledTask -TaskName 'StopAllInstances' -Confirm:$false 
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'StopAllInstances' -Description 'Stops All Instances' -User 'System' 