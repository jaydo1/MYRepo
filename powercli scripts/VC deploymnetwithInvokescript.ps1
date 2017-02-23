<#
.SYNOPSIS
   Script automates deployment of multiple vms loaded from pre-defined .csv file and invoke-script to do post deployment tasks 
.DESCRIPTION
   Script reads the .csv file, deploys vms from template, Renames hostname, set up IP configuration via VMware tools, Joins to domain,Runs Silent install of Orcale Listener and sets EBS institution settings via SQLPlus   
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
$vm.cluster = "Non_Prod_EBS_1_UN"
$vm.folder = "EBS4 Training Standalone"
$vm.template = "udvuxpoc004_gold1"
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
	#deploying new vm from template
				new-vm -name $vm.name -template $(get-template -name $vm.template) -vmhost $vmhost -datastore $(get-datastorecluster -name $vm.datastorecluster) -location $(get-folder -name $vm.folder) | Out-Null
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
	#Invoke-Script to change hostname 
				invoke-VMScript Get-VM -Name $computer -GuestUser 'Administrator' -GuestPassword 'LMBR123$' $ScriptText(get-content C:\powershellScripts\ServerRename) -ScriptType powershell 
	#Check if VMware Tools are running in the Deployed vm after Rename
				write-host "Waiting for reboot boot of $($computer)" -ForegroundColor Yellow
	    		do {
    	    		$toolsStatus = (Get-VM -name $computer).extensiondata.Guest.ToolsStatus
        			Start-Sleep -Seconds 30
					$GuestToolsStatus = (Get-View $computer -Property Guest).Guest.ToolsStatus
    			    } 
				until ( ($toolsStatus -match ‘toolsOk’) 
								
				if ($toolstatus -eq 'toolsOk'){  
				Write-Host (Get-Date).DateTime  
				Write-Host -ForegroundColor Green "$computer is up."
				}
				
	#Set new IP settings, needs Local Administrator credentials. Double check Subnet Mask and DNS IPs.  
				Set-VMGuestNetworkInterface -GuestUser 'Administrator' -GuestPassword 'LMBR123$' -VmGuestNetworkInterface $vmguestnic -IPPolicy Static -Ip $ip -Gateway $gw -Netmask 255.255.255.192 -Dns 10.7.70.33,10.7.71.33  
				Write-Host -ForegroundColor Green "Changing IP address."  
	#Change port group label.  
				Write-Host -ForegroundColor Green "Changing network label."  
				Get-VM -Name $computer | Get-NetworkAdapter  | Set-NetworkAdapter -NetworkName $label -connected:$true -StartConnected:$true -confirm:$false
	#Ping the server till it's successful  
				do {  
				Write-Host -ForegroundColor Green "Could not ping server $computer, sleeping for 10 seconds."  
				sleep 10  
				} while (((Get-WmiObject win32_pingstatus -Filter "address='$ip'").statuscode) -eq 1)
				
	#Add Changed network settings to Deployment report text file  
				Write-Host (Get-Date).DateTime  
				Write-Host -ForegroundColor Green "$computer ping was successful, writing new settings to DeploymentReport.txt file."  
				"`r`n New Settings" | Out-File C:\DeploymentLogs\DeploymentReport.txt -Append  
				$nic = Get-VM -Name $computer | Get-VMGuestNetworkInterface -GuestUser 'Administrator' -GuestPassword 'LMBR123$'  | Select Ip,SubnetMask,DefaultGateway,Dns,Mac  
				$nic | Out-File C:\DeploymentLogs\DeploymentReport.txt -Append  
				(Get-Date).DateTime | Out-File C:\DeploymentLogs\DeploymentReport.txt -Append  
				"`r`n-------------------------------------------------------------------------------------------------------------"| Out-File C:\DeploymentLogs\DeploymentReport.txt -Append 
  			
			else {  
				Write-Host (Get-Date).DateTime  
				Write-Host -ForegroundColor Green "$computer - cannot ping server, check if it's running. "  
				#Add server to issue text file  
				"`r`n" + (Get-Date).DateTime + "`r`n" + $computer | Out-File C:\deploymentLogs\issues.txt -Append 
			     }   	
				
	#Invoke-Script to change Join to the Domain  
				invoke-VMScript Get-VM -Name $computer -GuestUser 'Administrator' -GuestPassword 'LMBR123$' $ScriptText(get-content C:\powershellScripts\ServerJoinDomain) -ScriptType powershell
				write-host "Waiting for reboot boot of $($computer)" -ForegroundColor Yellow
	#Check if VMware Tools are running in the Deployed vm after Joining Domain 
	    		do {
    	    		$toolsStatus = (Get-VM -name $computer).extensiondata.Guest.ToolsStatus
        			Start-Sleep -Seconds 30
					$GuestToolsStatus = (Get-View $computer -Property Guest).Guest.ToolsStatus
    			    } 
				until ( ($toolsStatus -match ‘toolsOk’) 
								
				if ($toolstatus -eq 'toolsOk'){  
				Write-Host (Get-Date).DateTime  
				Write-Host -ForegroundColor Green "$computer is up starting post deployment tasks."
				}
	#Invoke-Script to the run silent install of Oracle Listener  
				invoke-VMScript Get-VM -Name $computer -GuestUser 'Administrator' -GuestPassword 'LMBR123$' $ScriptText(get-content C:\powershellScripts\OracleSilentListenerInstall) -ScriptType BAT
	#Invoke-Script to Start EBS services  
				invoke-VMScript Get-VM -Name $computer -GuestUser 'Administrator' -GuestPassword 'LMBR123$' $ScriptText(get-content C:\powershellScripts\StartServices) -ScriptType powershell
	#Invoke-Script to change EBS institute domain settings vis SQLPlus 
				invoke-VMScript Get-VM -Name $computer -GuestUser 'Administrator' -GuestPassword 'LMBR123$' $ScriptText(get-content C:\powershellScripts\LoopingUpdatewebconfigRCDomain) -ScriptType BAT
	#Invoke-Script to change EBS institute webconfig settings vis SQLPlus 
				invoke-VMScript Get-VM -Name $computer -GuestUser 'Administrator' -GuestPassword 'LMBR123$' $ScriptText(get-content C:\powershellScripts\LoopingUpdatewebconfigRCServiceUrl) -ScriptType BAT
								
				write-host "Post deployment tasks complete for $($computer)" -ForegroundColor Yellow
				Write-Host (Get-Date).DateTime  
				Write-Host -ForegroundColor Green "$computer is up."
				Write-Host "All vms deployed, exiting" -ForegroundColor Green
				}
								
	#disconnect vCenter
				Disconnect-VIServer -Confirm:$false
	} 	