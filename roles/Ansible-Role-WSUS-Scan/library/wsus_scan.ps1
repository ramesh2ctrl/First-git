#!powershell
#Requires -Module Ansible.ModuleUtils.Legacy
$ErrorActionPreference = "Stop"
$params = Parse-Args $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -default $false
$wsusserver = Get-AnsibleParam -obj $params -name "wsusserver" -type "str" -failifempty $true
$wsusport = Get-AnsibleParam -obj $params -name "wsusport" -type "str" -failifempty $true
$wsustargetgroup = Get-AnsibleParam -obj $params -name "wsustargetgroup" -type "str" -failifempty $true
$resultfolder = Get-AnsibleParam -obj $params -name "resultfolder" -type "paths" -failifempty $true
$resultziplocation = Get-AnsibleParam -obj $params -name "resultziplocation" -type "paths" -failifempty $true
$installationstates = Get-AnsibleParam -obj $params -name "installationstates" -type "str" -failifempty $true
$changeid = Get-AnsibleParam -obj $params -name "changeid" -type "str" -default "" -failifempty $false
${Script:WSUS_SERVER} = $wsusserver
${Script:WSUS_PORT} = $wsusport
${Script:TARGET_GROUP}= $wsustargetgroup
${Script:path} = $resultfolder 
${Script:ziplocation} = $resultziplocation
${Script:installationstates} = $installationstates  
$today = (Get-Date).ToUniversalTime()
$scan_time = $today.ToString('yyyy-MM-dd HH:mm:ss')

if(Test-Path ${Script:ziplocation})
    {
    Remove-Item -Path ${Script:ziplocation} -Force 
    }
if(Test-Path ${Script:path})
    {
    Remove-Item -Path ${Script:path}\*.csv -Force
    }
[void][reflection.assembly]::LoadWithPartialName('Microsoft.UpdateServices.Administration')
$script:wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer("${Script:WSUS_SERVER}", $False, "${Script:WSUS_PORT}")
$script:computerscope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope;
$script:computerscope.IncludeSubgroups = $True;
$script:computerscope.IncludeDownstreamComputerTargets = $True;
$script:computertargetgroupid = $script:wsus.GetComputerTargetGroups() | Where-Object {$_.Name -eq "${Script:TARGET_GROUP}"} | Select-Object -ExpandProperty Id;
$script:computertargetgroup = $script:wsus.GetComputerTargetGroup("${script:computertargetgroupid}");
$script:computerscope.ComputerTargetGroups.Add($script:computertargetgroup) | Out-Null;
$script:updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope;
$script:updatescope.ApprovedStates = 'Any';
$script:classifications = $script:wsus.GetUpdateClassifications()
$script:updatescope.Classifications.AddRange($script:classifications);
# My updated script:
[System.GC]::Collect()
$script:myupdates=@{}
$servers = $script:wsus.GetComputerTargets($script:computerscope)
foreach($s in $servers)
{
   $wsuskbnos = ""
   $all_artnos = @()
   $all_updates = @()
   if("$($s.FullDomainName)" -like '*.*')
      { 
      $s1 = "$($s.FullDomainName)".Split('.')[0]
      }
     else
      {
      $s1 = "$($s.FullDomainName)"
      } 
   $local:servers = $s
   $OsVersion = $s.ClientVersion.Build
   Add-Content -path ${Script:path}\$s1.csv  -value "$s1!OsVersion=$OsVersion!CurrencyDate=$scan_time!ScanType=ALL!Source=wsus" -encoding ascii
   $script:updatescope.IncludedInstallationStates = "${Script:installationstates}";
   $local:servers.GetUpdateInstallationInfoPerUpdate($script:updatescope) | %{ 
      if(! $script:myupdates.Contains($_.UpdateId)){
	     $u=$_.GetUpdate()
		 $script:myupdates.Add($_.UpdateId,($u.Title,$u.KnowledgebaseArticles[0]))
		 }
	  $_ | Select-Object `
         @{L='Device';E={$s1}}, `
         @{L='Status';E={$is="$($_.UpdateInstallationState)";if($is -eq "Installed"){"I"};if($is -eq "NotInstalled" -or $is -eq "Downloaded" -or $is -eq "Failed" -or $is -eq "InstalledPendingReboot"){"*"};if($is -eq "NotApplicable"){"NA"}}}, `
         @{L='FixNumber';E={"KB"+ $script:myupdates[$_.UpdateId][1] }}, `
         @{L='InstallDate';E={($s.LastReportedStatusTime).ToString("yyyy-MM-dd HH:mm:ss")}}, `
         @{L='Title';E={$script:myupdates[$_.UpdateId][0] }}, `
         @{L='ChangeTicket';E={$changeid}} 
	 } | ConvertTo-Csv -NoTypeInformation -Delimiter '!' | % {$_ -replace'"', "" } | Out-File -FilePath ${Script:path}\$s1.csv -append -en ascii -force
   $script:updatescope.IncludedInstallationStates = 'Installed'
   $wsuskbnos=($local:servers.GetUpdateInstallationInfoPerUpdate($script:updatescope))
   foreach ($wsuskbno in $wsuskbnos) {
     $superseederkb=""
	 $wsuskbno.GetUpdate()|%{ $superseederkb=$_.KnowledgebaseArticles[0]; $_.GetRelatedUpdates('UpdatesSupersededByThisUpdate') | %{ 
	   if(($_) -and ($_.KnowledgebaseArticles[0] -notin $all_artnos)){
          $superseding_entry = [pscustomobject]@{
             Device = "$s1"
             Status = "I"
             FixNumber = "KB$($_.KnowledgebaseArticles[0])"
             InstallDate = $scan_time
             Title = "Superseded update KB$($superseederkb)"
             ChangeTicket = "$changeid"
		     }
          $all_updates += $superseding_entry
          $all_artnos += $_.KnowledgebaseArticles[0]
          }
       }}
     }
   $all_updates |ConvertTo-Csv -NoTypeInformation  -delimiter '!'  | Select-Object -Skip 1 | % {$_ -replace '"', ""} | out-file -Force -FilePath ${Script:path}\$s1.csv -append -en ascii
} 
$script:myupdates=@{}
$all_updates = @()
[System.GC]::Collect()
Compress-Archive -Path ${Script:path}\*.csv  -CompressionLevel Optimal -DestinationPath  ${Script:ziplocation}
$result = @{result="Script Executed Successfully"}
Exit-Json $result
