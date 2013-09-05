#need to identify script folder
$ScriptPath = $MyInvocation.MyCommand.Path -replace $MyInvocation.MyCommand.Name;
#Network name of one of your management servers
$ManagementServer = "scom.contoso.com";
#GUID of your custom connector, this was specified when creating it
$strGuid = "{6A1F8C0E-B8F1-4147-8C9B-5A2F98F10007}";
#addresses for notification emails
$emailTo = 'azat.khadiev@contoso.com';
$emailFrom = 'scom@contoso.com';
#smtp server to send emails through
$Smtp = 'mail.contoso.com';

#Loading required assemblies for SCOM
$DLLs = ("Microsoft.EnterpriseManagement.Core.dll","Microsoft.EnterpriseManagement.OperationsManager.dll","Microsoft.EnterpriseManagement.Runtime.dll");
foreach ($lib in $DLLs)
{
    [Reflection.Assembly]::LoadFile($ScriptPath + $lib) | Out-Null
}

try
{
    #Getting connector object
    $mg = New-Object Microsoft.EnterpriseManagement.ManagementGroup($ManagementServer);
    $icfm = $mg.ConnectorFramework;
    $connectorGuid = New-Object Guid($strGuid);
    $connector = $icfm.GetConnector($connectorGuid);
    #getting new alerts
    $alerts = $connector.GetMonitoringAlerts();
}
catch
{
    Write-Host $_.Exception.Message.ToString();
    exit 2;
}

if ($alerts.Count -gt 0)
{
    #signaling scom, that these alert were already processed
    $connector.AcknowledgeMonitoringAlerts($alerts);

    foreach ($alert in $alerts)
    {
        try
        {
            #Here is the main action on my alert.
            $alertContext = [xml]$alert.Context;
            $alertResolutionStateName = @{0="New";255="Closed"};
            $monitorClass = $alertContext.SelectNodes("//Property[@Name='__CLASS']/text()").Value;

            $subject = "This is an alert message from SCOM";
            $emailBody = "`n" + $alertResolutionStateName[[int]$alert.ResolutionState] + "`n" + $alert.MonitoringObjectFullName + "`n" + $alert.TimeRaised + "`n" + $monitorClass;       
        
            Send-MailMessage -SmtpServer $Smtp -Subject $subject -From $emailFrom -To $emailTo -Body $emailBody
            
            #$alert.CustomField1 = "Notification sent.";
            #$alert.Update();
        }
        catch
        {
            Write-Host $_.Exception.Message.ToString();
        }
    }
} 
else
{
    Write-Host "Task executed successfully. No new alerts.";
}
