# create folder if it does not exist yet 
$path = "$home\Documents\Scripts"
$exists = Test-Path -Path $path
if (!$exists)
{
  $null = New-Item -ItemType Directory -Path $path
}
 
# create new scripts: drive 
New-PSDrive -Name scripts -PSProvider FileSystem -Root "$home\Documents\Scripts" -Persist
 
dir scripts: 

