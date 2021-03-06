# get the latest reboot event from the System event log 
$e = Get-EventLog System -Source Microsoft-Windows-Kernel-General -InstanceId 12 -Newest 1
# read time information from collection of event info 
$e.ReplacementStrings[-1]
# turn info in DateTime 
$reboot = [DateTime]$e.ReplacementStrings[-1]
$reboot 
"System was last rebooted: $reboot" 
$timespan = New-TimeSpan -Start $reboot
$days = $timespan.Days
"System is running for more than $days days." 
