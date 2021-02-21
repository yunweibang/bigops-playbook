
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
$output_file_tmp="$basedir/syskey.tmp"

# 获取CPU使用率

$cpu = gwmi win32_Processor
$cpu_usage = "{0:0.0}" -f $cpu.LoadPercentage

if ($cpu_usage)
{
  Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "cpu_usage $cpu_usage"
}

# 获取内存使用率

$mem = Get-WmiObject -Class win32_OperatingSystem
$Allmen = ($mem.TotalVisibleMemorySize  / 1KB) 
$Freemen = ($mem.FreePhysicalMemory  / 1KB) 
$mem_usage = "{0:0.0}" -f ((($mem.TotalVisibleMemorySize-$mem.FreePhysicalMemory)/$mem.TotalVisibleMemorySize)*100)

if ($mem_usage)
{
  Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "mem_usage $mem_usage"
}

# 获取磁盘使用率

$disk = Get-WmiObject -Class win32_logicaldisk -filter "drivetype = 3"
$allSpace = $disk.Size 
$allSpace =(($allSpace | Measure-Object -Sum).sum /1gb)
$FreeSpace = $disk.FreeSpace 
$FreeSpace =(($FreeSpace | Measure-Object -Sum).sum /1gb)
$disk_total_usage = "{0:0.0}" -f ((($allSpace - $FreeSpace)/$allSpace)*100)

if ($disk_total_usage)
{
  Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "disk_total_usage $disk_total_usage"
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
      Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "$tcp_info 1"
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
      Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "$udp_info 1"
    }
  }


# 获取进程状态

foreach($file in tasklist /v /fo csv|convertfrom-csv|select '映像名称')
{
  $imagename1 = "$File.映像名称"
  if ($imagename1)
  {
    $imagename1 = 'proc_status{name="' + "$imagename1" + '"}'
    Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "$imagename1 1"
  }
}

foreach($file in tasklist /v /fo csv|convertfrom-csv|select 'imagename')
{
  $imagename2 = "$File.imagename"
  if ($imagename2)
  {
    $imagename2 = 'proc_status{name="' + "$imagename2" + '"}'
    Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "$imagename2 1"
  }
}

foreach($file in tasklist /v /fo csv|convertfrom-csv|select 'Image Name')
{
  $imagename3 = "$File.Image Name"
  if ($imagename3)
  {
    $imagename3 = 'proc_status{name="' + "$imagename3" + '"}'
    Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "$imagename3 1"
  }
}

# 获取网络连接状态

$tcp_total= netstat -an ; $tcp_total=$tcp_total.count;
$tcp_estab = netstat -an | select-string "ESTABLISHED";$tcp_estab=$tcp_estab.count;
$tcp_synrecv = netstat -an | select-string "SYN_RECV";$tcp_synrecv=$tcp_synrecv.count;
$tcp_timewait = netstat -an | select-string "TIME_WAIT";$tcp_timewait=$tcp_timewait.count;

Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "tcp_total $tcp_total"
Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "tcp_estab $tcp_estab"
Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "tcp_synrecv $tcp_synrecv"
Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "tcp_timewait $tcp_timewait"


# 获取分区使用率

gwmi win32_logicaldisk -filter "drivetype = 3" | % {
  $disk_fs='disk_fs_usage{volume="' + $_.deviceid +'"} '+ (($_.size-$_.freespace)/$_.size*100)
  Add-Content -Path "$output_file_tmp" -Encoding Ascii -Value "$disk_fs"
}

Get-Content $output_file_tmp | Select-Object -unique|Set-content $output_file

Remove-Item $output_file_tmp

}


