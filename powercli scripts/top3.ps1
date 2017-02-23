Get-EventLog -LogName System -EntryType Error |
  Group-Object -Property Source |
  Sort-Object -Property Count -Descending |
  Select-Object -First 3 -Property Count, Name 
