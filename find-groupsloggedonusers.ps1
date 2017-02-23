#requires -Version 1 
try 
{  
  $groups = ([Security.Principal.WindowsIdentity]::GetCurrent()).Groups |
  ForEach-Object {
    $_.Translate([Security.Principal.NTAccount])
  } | Sort-Object
} 
catch 
{ 
  Write-Warning 'Groups could not be retrieved.'
}
 
$groups 
