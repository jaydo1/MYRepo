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
Function Set-WinVMIP ($fVMN, $fGuestUser, $fGuestPassword, $fIPi, $fSNMi, $fGWi, $fvmguestnic){
 $netsh = "c:\windows\system32\netsh.exe interface ip set address ""$($fvmguestnic)"" static $fIPi $fSNMi $fGWi 1"
 $netshdns = "c:\windows\system32\netsh.exe interface ip set dns ""$($fvmguestnic)"" static 10.7.70.33 None"
 $netshdns2 = "c:\windows\system32\netsh.exe interface ip add dns ""$($fvmguestnic)"" 10.7.71.33"
 Write-Host "Setting IP address for $fVMN..."
 Write-Host $netsh
 Invoke-VMScript -VM $fVMN -GuestUser $fGuestUser -GuestPassword $fGuestPassword -ScriptType bat -ScriptText $netsh
 Invoke-VMScript -VM $fVMN -GuestUser $fGuestUser -GuestPassword $fGuestPassword -ScriptType bat -ScriptText $netshdns
 Invoke-VMScript -VM $fVMN -GuestUser $fGuestUser -GuestPassword $fGuestPassword -ScriptType bat -ScriptText $netshdns2
 Write-Host "Setting IP address completed."
}

#variables
$csvfile = "C:\powershellScripts\vms2deploy.csv"
$label = 'vlan0766-p1npebsun'
$vcenter = "PW0992VIVCR001.vi.det.nsw.edu.au" 
$vmcluster = "Non_Prod_EBS_1_UN"
$vmfolder = "EBS4 Training Standalone"
$vmtemplate = "udvuxpoc004_gold2"
$timeout = 1800
$loop_control = 0
$GuestUser = 'Administrator'
$GuestPassword = 'LMBR123$'
$domJoinDomain = "detnsw.win"
$domJoinAcc = "srvE4Standalonedomjoin"
$domJoinPwd = "TwE92cm6Zm84laSoOvKX"


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
	Write-host "Checking Variables from CSV	
		$($vm.Name)
		$($vm.ip)
		$($vm.gw)
		"
	$ip = $vm.ip 
	$gw = $vm.gw  
	
	
    #validate input, at least vm name, template name 
		if (($vm.Name -ne "") -and ($vmtemplate -ne "") ){
			
	#check if vm with this name already exists 
			if (!(get-vm $vm.Name -erroraction 0)){
				
				$vmhost = get-cluster $vmcluster | get-vmhost -state connected | Get-Random
	#deploying new vm from template
				new-vm -name $vm.name -template $(get-template -name $vmtemplate) -vmhost $vmhost -datastore $(get-datastorecluster -name "npebs1un-xivun01-dsc") -location $(get-folder -name $vmfolder) | Out-Null
    # track deployment progress
					
				write-host "Starting VM $($vm.Name)"
    			start-vm -vm $vm.Name -confirm:$false | Out-Null
				$loop_control = 0
	    		do {
    	    		$toolsStatus = $vmobj.extensiondata.Guest.ToolsStatus
        			Start-Sleep 3
					$loop_control++
    			} until ( ($toolsStatus -match 'toolsOk') -or ($loop_control -gt $timeout) )
				
				
			}
	
		
				$vmobj = Get-VM $vm.name			

				$loop_control = 0
	    		do {
    	    		$toolsStatus = $vmobj.extensiondata.Guest.ToolsStatus
        			Start-Sleep 3
					$loop_control++
    			} until ( ($toolsStatus -match 'toolsOk') -or ($loop_control -gt $timeout) )
		
		
	#Set new IP settings, needs Local Administrator credentials. Double check Subnet Mask and DNS IPs. 
				$vmguestnic = $vmobj | Get-VMGuestNetworkInterface -GuestUser $GuestUser -GuestPassword $GuestPassword
 
				Write-Host -ForegroundColor Green "Changing IP address."  

				$SNMi = "255.255.255.192"

				Set-WinVMIP $vmobj $GuestUser $GuestPassword $ip $SNMi $gw $vmguestnic
				
	#Change port group label.  
				Write-Host -ForegroundColor Green "Changing network label."  
				$vmobj | Get-NetworkAdapter  | Set-NetworkAdapter -NetworkName $label -connected:$true -StartConnected:$true -confirm:$false
	#Ping the server till it's successful  
				do {  
				Write-Host -ForegroundColor Red "Could not ping server $vm.name, sleeping for 10 seconds."  
				sleep 10  
				} while (((Get-WmiObject win32_pingstatus -Filter "address='$ip'").statuscode) -eq 1)
				Write-Host -ForegroundColor Green "Ping Success - server $vm.name" 


function runInvokeVMScript($scriptData,$scriptType)
{
	try
	{
		$timeout = new-timespan -seconds 300
		$sw = [diagnostics.stopwatch]::StartNew()
		
		$toolsStatus = ""
		
		do 
		{
			$toolsStatus = (Get-VM $vm.name | Get-View).Guest.ToolsStatus
			write-host "Checking VMTools status"				
			sleep 5
		} until (($toolsStatus -eq 'toolsOk') -or ($sw.elapsed -gt $timeout) -or ($toolsStatus -eq 'toolsOld'))
			
		if(($toolsStatus -eq 'toolsOk') -or ($toolsStatus -eq 'toolsOld'))
		{
			write-host "$toolsStatus" -ForegroundColor Green
			
			#Invoke-Script to change hostname 
			try
			{
				#Define script to be run remotely
				write-host "Running script on remote VM: `n`"$script`"" -ForegroundColor Yellow
				
				Invoke-VMScript -VM $vm.name -GuestUser Administrator -GuestPassword $loca -ScriptText $scriptData -ScriptType $scriptType
				
				write-host "Script has run remotely" -ForegroundColor Green
			}
			catch
			{
				write-host "Failed to run remote script: `[$($Error[0].Exception.InnerException.Message)`]" -ForegroundColor Red
			}
		}
		else
		{
			write-host "Timeout reached, OS did not respond." -ForegroundColor Red
		}
	}#end try get VM tools status
	catch
	{
		write-host = "Failed to detect VM Tools: `[$($Error[0].Exception.InnerException.Message)`]" -ForegroundColor Red
	}
}
	#Change hotname
			$script = "Rename-Computer -NewName $($vm.name) -Restart"
			runInvokeVMScript $script "powershell"
			
	#Join to the domain
			$script = "Add-Computer -Computername $($vm.name) -DomainName $domJoinDomain -Credential `$(new-object -typename System.Management.Automation.PSCredential -argumentlist '$domJoinDomain\$domJoinAcc',`$(ConvertTo-SecureString $($domJoinPwd) -AsPlainText -Force)) -Restart"										
			runInvokeVMScript $script "powershell"	
			
	#Install Oracle Listener
			$script = "C:\app\Administrator\product\11.2.0\dbhome_1\bin\netca.bat /silent /responsefile C:\app\Administrator\product\11.2.0\dbhome_1\network\admin\netca.rsp"
			runInvokeVMScript $script "bat"
		
	#Start EBS services
			$script = "get-service 'ebs*' | where status -eq 'Stopped' | Start-Service"
			runInvokeVMScript $script "powershell"
			
	#Set Institute settings domain
			$script = "sqlplus / as sysdba @C:\Utilities\LoopingUpdatewebconfigRCDomainandRCURL.sql"
			runInvokeVMScript $script "bat"
			
				
		}#end if VM not found
		else
		{
			Write-Host "VM $($vm.name) exists, skipping ..." -ForegroundColor Red
		}
	}#end if VM exists

}#end foreach VM
#disconnect vCenter
			Disconnect-VIServer * -Confirm:$false