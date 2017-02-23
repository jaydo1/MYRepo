<#
.SYNOPSIS
   Script automates deployment of multiple vms loaded from pre-defined .csv file
.DESCRIPTION
   Script reads the .csv file, deploys vms from template, and set up IP configuration via VMware tools 
.PARAMETER 
   none
.EXAMPLE
   trivia
#>

#variables
$csvfile = "C:\powershellScripts\vms2deploy.csv"
$computer = $_.name  
$ip = $_.ip  
$gw = $_.gw  
$label = 'vlan0766-p1npebsun'
$vcenter = "PW0992VIVCR001.vi.det.nsw.edu.au" 
$vm.cluster = Non_Prod_EBS_1_UN
$vm.folder = EBS4 Training Standalone
$vm.template = udvuxpoc004_gold1
$timeout = 1800
$loop_control = 0

$vmsnapin = Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue
$Error.Clear()
if ($vmsnapin -eq $null) 	
	{
	Add-PSSnapin VMware.VimAutomation.Core
	if ($error.Count -eq 0)
		{
		write-host "PowerCLI VimAutomation.Core Snap-in was successfully enabled." -ForegroundColor Green
		}
	else
		{
		write-host "ERROR: Could not enable PowerCLI VimAutomation.Core Snap-in, exiting script" -ForegroundColor Red
		Exit
		}
	
	else
	{
	Write-Host "PowerCLI VimAutomation.Core Snap-in is already enabled" -ForegroundColor Green
	}
	
#Connect to vcenter server  
	connect-viserver $vcenter  

	$vms2deploy = Import-Csv -Path $csvfile
	
#deploy vms as per information in each line, 
	foreach ($vm in $vms2deploy) {
		
    #validate input, at least vm name, template name 
		if (($computer -ne "") -and ($vm.template -ne "") ){
			
	#check if vm with this name already exists 
			if (!(get-vm $computer -erroraction 0)){
				$vmhost = get-cluster $vm.cluster | get-vmhost -state connected | Get-Random
    			                				
                # track deployment progress
                $loop_control = 0
				write-host "Starting VM $($computer)"
    			start-vm -vm $computer -confirm:$false | Out-Null
				
				if ($loop_control -gt $timeout){
					Write-Host "Deployment of $($computer) took more than $($timeout/20) minutes, check if everything OK" -ForegroundColor red
				}
				else {
				Write-Host "$($computer) successfully deployed, moving on" -ForegroundColor Green
				}
				else {
				Write-Host "$($computer) already exists, moving on" -ForegroundColor Red
				}
				write-host "Waiting for first boot of $($computer)" -ForegroundColor Yellow
	    		do {
    	    		$toolsStatus = (Get-VM -name $computer).extensiondata.Guest.ToolsStatus
        			Start-Sleep 3
					$loop_control++
    			} until ( ($toolsStatus -match ‘toolsOk’) -or ($loop_control -gt $timeout) )
				}
	#Check if VMware Tools are running in the Deployed vm 				
				$toolstatus = (Get-VM $computer | Get-View).Guest.ToolsStatus  
				if ($toolstatus -eq 'toolsOk'){  
				Write-Host (Get-Date).DateTime  
				Write-Host -ForegroundColor Green "$computer is up."
				}
	#Read current network settings, needs local Admin credentials  
				$vmguestnic = Get-VM -Name $computer | Get-VMGuestNetworkInterface -GuestUser 'Administrator>' -GuestPassword 'LMBR123$'  -ToolsWaitSecs 30
				
				#Set new IP settings, needs Local Administrator credentials. Double check Subnet Mask and DNS IPs.  
				Set-VMGuestNetworkInterface -GuestUser 'Administrator' -GuestPassword 'LMBR123$' -VmGuestNetworkInterface $vmguestnic -IPPolicy Static -Ip $ip -Gateway $gw -Netmask 255.255.255.192 -Dns 10.7.70.33,10.7.71.33  
				Write-Host -ForegroundColor Green "Changing IP address."  
			   
	#Change port group label.  
				Write-Host -ForegroundColor Green "Changing network label."  
				Get-VM -Name $computer | Get-NetworkAdapter  | Set-NetworkAdapter -NetworkName $label -connected:$true -StartConnected:$true -confirm:$false
				
	#Ping the server till it's successful  
				do {  
				Write-Host -ForegroundColor Green "Could not ping server $computer, sleeping for 5 seconds."  
				sleep 5  
				} while (((Get-WmiObject win32_pingstatus -Filter "address='$ip'").statuscode) -eq 1)
				
	#Add current network settings to report text file  
				Write-Host (Get-Date).DateTime  
				Write-Host -ForegroundColor Green "$computer ping was successful, writing new settings to report.txt file."  
				"`r`n New Settings" | Out-File C:\report.txt -Append  
				$nic = Get-VM -Name $computer | Get-VMGuestNetworkInterface -GuestUser '<Domain Admin>' -GuestPassword '<Domain Admin Password>'  | Select Ip,SubnetMask,DefaultGateway,Dns,Mac  
				$nic | Out-File C:\report.txt -Append  
				(Get-Date).DateTime | Out-File C:\report.txt -Append  
				"`r`n-------------------------------------------------------------------------------------------------------------"| Out-File C:\report.txt -Append  
  			
			else {  
				Write-Host (Get-Date).DateTime  
				Write-Host -ForegroundColor Green "$computer - cannot ping server, check if it's running. "  
				#Add server to issue text file  
				"`r`n" + (Get-Date).DateTime + "`r`n" + $computer | Out-File C:\issues.txt -Append 
			     }   	
				

				Write-Host "All vms deployed, exiting" -ForegroundColor Green
	#disconnect vCenter
	Disconnect-VIServer -Confirm:$false
	


} 	