Function Connect-EC2Instance{
    
    <#
    .SYNOPSIS
        Connects to EC2 instances in AWS without needing to decrypt the password manually using a pem file.
    .DESCRIPTION
        Automatically figues out password for instance if the pem file is found, and connects via RDP.
        Assumes development environment with AWS default profile name "dev".
        Looks to default path in your documents for pem files under $environment directory.
        You can specify path and file name of pem if needed.
    
    .PARAMETER InstanceId
        The AWS Id of the instance.
    
    .PARAMETER Environment
        The AWS profile name, usually mapped to an environment name.
    
    .PARAMETER KeyName
        If not gotten from the properties of the EC2 instance, the pem key file name.
    
    .PARAMETER KeyPath
        The path to the pem key file name.
    
    .EXAMPLE
        Connect-Ec2instance i-12345678
        No arguments given. Assumes "dev" AWS profile. Figures out pem key name from EC2 instance properties.
    
    .EXAMPLE
        Connect-Ec2instance i-12345678 -Environment production
        Connects to EC2 instance in the "production" AWS profile.  Figures out pem key name from EC2 instance properties.
    
    .EXAMPLE
        Connect-Ec2instance i-12345678 -Environment production -KeyName myproductionpem.pem -KeyPath c:\super\secret\path
        Specify pem key filename and path, if not defaults.
    .NOTES
        Written to work with Jaap Brasser's Connect-Mstsc function - https://gallery.technet.microsoft.com/scriptcenter/Connect-Mstsc-Open-RDP-2064b10b
        Author: Kirk Brady
        Site: https://github.com/kirkbrady
 
        Version History
        1.0.0 - Initial release
    #>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [alias("Instance","Computer","ComputerName","MachineName")]
            [string]$InstanceId,
        [Parameter(Mandatory=$false,Position=1)]
        [alias("Env")]
            [string]$Environment="dev",
        [Parameter(Mandatory=$false,Position=2)]
        [alias("Key","Pem")]
            [string]$KeyName,
        [Parameter(Mandatory=$false,Position=3)]
        [alias("Path","PemPath")]
            [string]$KeyPath="$env:USERPROFILE\Documents\pem\$Environment"
    )
    Begin {
        Write-Output "Initializing AWS defaults."
        Initialize-AWSDefaults -ProfileName $Environment -Region ap-southeast-2
        }

    Process {
        Try {
            If(!$KeyName){
                [string]$KeyName=(Get-EC2Instance -InstanceId $InstanceId).Instances.Keyname
            }

            $PemFile = "$Keypath\$Keyname.pem"

            If(Test-Path $Pemfile){
                Write-Output "Target PEM file is $PemFile"

                $Pass = Get-EC2PasswordData -InstanceId $InstanceId -PemFile $PemFile -Decrypt
                $PrivateIP = (Get-EC2Instance $InstanceId).RunningInstance.PrivateIpAddress

                Connect-Mstsc -computername $PrivateIP -password $Pass -user Administrator
            } else {
                Write-Output "Key `"$KeyName`" not found in path $PemFile"
            }
        }
        Catch {
            $_.Exception
        }
    }
    
    End {
    }
}
