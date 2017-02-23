#requires -Version 2 
NETSTAT.EXE -anop tcp|
Select-Object -Skip  4|
ForEach-Object -Process {
  [regex]::replace($_.trim(),'\s+',' ')
}|
ConvertFrom-Csv -d ' ' -Header 'proto', 'src', 'dst', 'state', 'pid'|
Select-Object -Property src, state, @{
  name = 'process'
  expression = {
    (Get-Process -PipelineVariable $_.pid).name
  }
} |
Format-List 
