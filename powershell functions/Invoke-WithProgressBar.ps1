function Invoke-WithProgressBar
{
  param
  (
    [Parameter(Mandatory)]
    [ScriptBlock]
    $Task
  )
  
  try
  {
    $ps = [PowerShell]::Create()
    $null = $ps.AddScript($Task)
    $handle = $ps.BeginInvoke()
  
    $i = 0
    while(!$handle.IsCompleted)
    {
      Write-Progress -Activity 'Hang in...' -Status $i -PercentComplete ($i % 100)
      $i++
      Start-Sleep -Milliseconds 300
    }
    Write-Progress -Activity 'Hang in...' -Status $i -Completed
    $ps.EndInvoke($handle)
  }
  finally
  {
    $ps.Stop()
    $ps.Runspace.Close()
    $ps.Dispose()
  } 
} 
