param( ${Script:WSUS_SERVER} = "localhost",
${Script:WSUS_PORT} = "8530",
${Script:TARGET_GROUP}="All Computers",
${Script:path} = "C:\Report",
${Script:ziplocation} = "C:\ziplocation\report.zip", $secureconnection = $false)
${Script:installationstates} =  'NotInstalled, Installed, NotApplicable'  
[void][reflection.assembly]::LoadWithPartialName('Microsoft.UpdateServices.Administration')
$script:wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer("${Script:WSUS_SERVER}", $secureconnection, "${Script:WSUS_PORT}")
$script:computerscope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope;
$script:computertargetgroupid = $script:wsus.GetComputerTargetGroups() | Where-Object {$_.Name -eq "${Script:TARGET_GROUP}"} | Select-Object -ExpandProperty Id;
$script:computertargetgroup = $script:wsus.GetComputerTargetGroup("${script:computertargetgroupid}");
$script:computerscope.ComputerTargetGroups.Add($script:computertargetgroup) | Out-Null;
$script:updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope;
$script:updatescope.ApprovedStates = 'Any';
$script:classifications = $script:wsus.GetUpdateClassifications()
$script:updatescope.Classifications.AddRange($script:classifications);
$script:updatescope.IncludedInstallationStates = "${Script:installationstates}"
$script:wsus.GetSummariesPerComputerTarget($script:updatescope,$script:computerscope) | Format-Table @{L='ComputerTarget';E={($wsus.GetComputerTarget([guid]$_.ComputerTargetId)).FullDomainName}}, 
@{L='InstalledOrNotApplicablePercentage';E={(($_.NotApplicablecount+ $_.Installedcount)/($_.NotApplicablecount+ $_.Installedcount+$_.NotInstalledCount))*100}} 
