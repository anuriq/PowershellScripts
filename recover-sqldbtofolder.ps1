$ProtectionGroupName = "PG name, get from GUI for example";
$DBName = 'DB_Name';
$TargetServerName = 'restoresrv.contoso.com';
$RestoreLocation = 'C:\restored_db';
$DPMServer = 'backup.contoso.com';

Connect-DPMServer $DPMServer | Out-Null

$prot_group = Get-ProtectionGroup -DPMServerName $DPMServer | where {$_.FriendlyName -eq $ProtectionGroupName}
$data_source = Get-Datasource -ProtectionGroup $prot_group | where {$_.Name -like "*$DBName*"}
$rec_point = Get-RecoveryPoint -Datasource $data_source | where {$_.IsIncremental -eq $false } | sort -Property RepresentedPointInTime -Descending | select -first 1
$rec_opt = New-RecoveryOption -SQL -TargetServer $TargetServerName -RecoveryLocation CopyToFolder -RecoveryType Restore -TargetLocation $RestoreLocation
$rec_job = Recover-RecoverableItem -RecoveryOption $rec_opt -RecoverableItem $rec_point

while ($rec_job.HasCompleted -eq $False)
{
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

if ($rec_job.HasCompleted -eq $True -and $rec_job.Status -eq "Succeeded")
{
    Write-Host -ForegroundColor Green "All is fine";
    exit 0;
} else {
    Write-Host -ForegroundColor Green "Encountered a problem";
    $rec_job | fl;
    exit 2;
}
