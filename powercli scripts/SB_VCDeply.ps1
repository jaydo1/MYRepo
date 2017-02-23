$csvfile = "C:\Users\sbochin\Desktop\Jamies Script\vms2deploy.csv"
$vcenter = "PW0992VIVCR001.vi.det.nsw.edu.au" 
$loca = "LMBR123$"

$domJoinDomain = "detnsw.win"
$domJoinAcc = "srvE4Standalonedomjoin"
$domJoinPwd = "TwE92cm6Zm84laSoOvKX"

$vms2deploy = Import-Csv -Path $csvfile

$Error.Clear()
#Load VMware Snapin
try
{
    if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null )
    {
        Add-PSSnapin VMware.VimAutomation.Core | Out-Null
		write-host "VMware snapin loaded"
    }#if 
	else
	{
		write-host "VMware snapin already loaded"
	}
}#try load VMware Snapin
catch
{
    write-host "Could not load VMware snapin. `[$($Error[0].Exception.InnerException.Message)`]" -ForegroundColor Red
}

#Connect to vcenter server  
connect-viserver $vcenter

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

#deploy vms as per information in each line, 
foreach ($vm in $vms2deploy) 
{
	#validate input, at least vm name, template name 
	if (($vm.name -ne "") -and ($vmtemplate -ne "") )
	{
		#check if vm with this name already exists
		#if (!(get-vm $vm.name -ErrorAction SilentlyContinue) -and ($vm.name -eq "ew0000se4trn004"))
		
		#test only
		if ((get-vm $vm.name -ErrorAction SilentlyContinue) -and ($vm.name -eq "ew0000se4trn004"))
		{
			write-host "Setting up VM: $($vm.name)"
			#Insert Code from Chris to create VM from template / networking
			
			#-------
			
			<#
			#Change hotname
			$script = "Rename-Computer -NewName $($vm.name) -Restart"
			runInvokeVMScript $script "powershell"
			
			#Join to the domain
			$script = "Add-Computer -Computername $($vm.name) -DomainName $domJoinDomain -Credential `$(new-object -typename System.Management.Automation.PSCredential -argumentlist '$domJoinDomain\$domJoinAcc',`$(ConvertTo-SecureString $($domJoinPwd) -AsPlainText -Force)) -Restart"										
			runInvokeVMScript $script "powershell"	
			
			#Install Oracle Listener
			$script = "C:\app\Administrator\product\11.2.0\dbhome_1\bin\netca.bat /silent /responsefile C:\app\Administrator\product\11.2.0\dbhome_1\network\admin\netca.rsp"
			runInvokeVMScript $script "bat"
			#>
			
			#Start EBS services
			$script = "get-service 'ebs*' | where status -eq 'Stopped' | Start-Service"
			runInvokeVMScript $script "powershell"
			
			#Set Institute settings domain
			$script = "sqlplus / as sysdba @c:\****\**.sql"
			runInvokeVMScript $script "bat"
			
			#Set Institute settings webconfig
			$script = "sqlplus / as sysdba @c:\****\**.sql"
			runInvokeVMScript $script "bat"
			
		}#end if VM not found
		else
		{
			Write-Host "VM $($vm.name) exists, skipping ..." -ForegroundColor Red
		}
	}#end if VM exists


}#end foreach VM