
function Invoke-TimeOutCommand()
{
    param(
    [int]$Timeout,
    [ScriptBlock]$ScriptBlock
    )
   $job = Start-Job -ScriptBlock $ScriptBlock
   $job | Wait-Job -Timeout $Timeout
   if($job.State -ne 'Completed')
   {
        Write-Warning 'timeout'
        $job | Stop-Job | Remove-Job
        return $null
   }
   else
   {
     return $job | Receive-Job
   }
}
 
Invoke-TimeOutCommand -Timeout 15 -ScriptBlock {

$basedir="c:/Program Files (x86)/wmi_exporter/key"
$output_file="$basedir/syskey.prom"
$output_file_tmp="$basedir/syskey.prom.tmp"
Set-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value ""

# 获取CPU使用率

function cpu_usage()
{
  $cpu = Get-WmiObject -Class Win32_Processor 
  $Havecpu = $cpu.LoadPercentage 
  return @($Havecpu.tostring("f2"))
}

# 获取内存使用率

function mem_usage()
{
  $mem = Get-WmiObject -Class win32_OperatingSystem
  $Allmen = ($mem.TotalVisibleMemorySize  / 1KB) 
  $Freemen = ($mem.FreePhysicalMemory  / 1KB) 
  $Permem =  ((($mem.TotalVisibleMemorySize-$mem.FreePhysicalMemory)/$mem.TotalVisibleMemorySize)*100)
  return @($Permem.tostring("f2"))
}

# 获取磁盘使用率

function disk_usage(){
  $disk = Get-WmiObject -Class win32_logicaldisk -filter "drivetype = 3"
  $allSpace = $disk.Size 
  $allSpace =(($allSpace | Measure-Object -Sum).sum /1gb)
  $FreeSpace = $disk.FreeSpace 
  $FreeSpace =(($FreeSpace | Measure-Object -Sum).sum /1gb)
  $disk_used_percent = ((($allSpace - $FreeSpace)/$allSpace)*100)
  return @($disk_used_percent.tostring("f2"))
}

# 获取tcp端口状态

netstat -ano|findstr /i "TCP "|findstr /i "LISTENING"|findstr -v "\[::\]" |
  ForEach-Object{
    $i = $_ | Select-Object -Property Protocol , Source , Destination , Mode ,pid
    $null, $i.Protocol, $i.Source, $i.Destination, $i.Mode, $i.pid=($_ -split '\s{2,}')
    $tcp = ($i.Source -split ':')[1]
    if ($tcp)
    {
      $tcp_info='tcp_port_status{port="' + "$tcp" + '"}'
      Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "$tcp_info 1`n"
    }
  }

# 获取udp端口状态

netstat -ano|findstr /i "UDP "|findstr -v "\[::\]" |
  ForEach-Object{
    $i = $_ | Select-Object -Property Protocol , Source , Destination , Mode ,pid
    $null, $i.Protocol, $i.Source, $i.Destination, $i.Mode, $i.pid=($_ -split '\s{2,}')  
    $udp = ($i.Source -split ':')[1]
    if ($udp)
    {
      $udp_info='udp_port_status{port="' + "$udp" + '"}'
      Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "$udp_info 1`n"
    }
  }


# 获取进程状态

#Get-WmiObject Win32_Service -filter "State = 'Running'" | % {
#  $proc=$_.Name -replace '[ ]','_'
#  Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "proc_status{proc=\"$proc\"} 1`n"
#}


# 获取网络连接状态


$tcp_total= netstat -an ; $tcp_total=$tcp_total.count;
$tcp_estab = netstat -an | select-string "ESTABLISHED";$tcp_estab=$tcp_estab.count;
$tcp_synrecv = netstat -an | select-string "SYN_RECV";$tcp_synrecv=$tcp_synrecv.count;
$tcp_timewait = netstat -an | select-string "TIME_WAIT";$tcp_timewait=$tcp_timewait.count;

Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "tcp_total $tcp_total`n"
Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "tcp_estab $tcp_estab`n"
Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "tcp_synrecv $tcp_synrecv`n"
Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "tcp_timewait $tcp_timewait`n"


# 获取分区使用率

gwmi win32_logicaldisk -filter "drivetype = 3" | % {
  $diskpart='diskpart_fs{volume="' + $_.deviceid +'"} '+ (($_.size-$_.freespace)/$_.size*100).tostring("f2") + "`n"
  Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "$diskpart"
}


if ($(cpu_usage))
{
  Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "cpu_usage $(cpu_usage)`n"
}

if ($(mem_usage))
{
  Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "mem_usage $(mem_usage)`n"
}

if ($(disk_usage))
{
  Add-Content -Path "$output_file_tmp" -Encoding Ascii -NoNewline -Value "disk_usage $(disk_usage)`n"
}

Move-Item "$output_file_tmp" "$output_file" -force

}


