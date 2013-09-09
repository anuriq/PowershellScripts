param(
    #Action can be InstallConector or UninstallConector
    [parameter(Mandatory=$true)]$Action,
    [parameter(Mandatory=$true)]$ConnectorName,
    #Your management server network name
    [parameter(Mandatory=$true)]$ManagementServer
)

$ErrorActionPreference = "Stop";
$ScriptPath = $MyInvocation.MyCommand.Path -replace $MyInvocation.MyCommand.Name;

if ($Action -ne "InstallConnector" -and $Action -ne "UninstallConnector")
{
    Write-Host -ForegroundColor Red "Action can be InstallConnector or UninstallConnector";
    exit 3;
}

try
{
    #We need to load SCOM assemblies to use its classes
    $DLLs = ("Microsoft.EnterpriseManagement.Core.dll","Microsoft.EnterpriseManagement.OperationsManager.dll","Microsoft.EnterpriseManagement.Runtime.dll");
    foreach ($lib in $DLLs)
    {
        [Reflection.Assembly]::LoadFile($ScriptPath + $lib) | Out-Null
    }
}
catch
{
    $exception = $_.Exception.Message;
    Write-Host -ForegroundColor Red "Could not load assemblies, they should be in the same folder with script: " + $exception;
    exit 3;
}

#This GUID is customizable, it is important to use the same one in all scripts working with this connector
$connectorGuid = New-Object Guid("{6A1F8C0E-B8F1-4147-8C9B-5A2F98F10007}");
            
if ($action -eq "InstallConnector")
{
    $mg = New-Object Microsoft.EnterpriseManagement.ManagementGroup($ManagementServer);
    $icfm = $mg.ConnectorFramework;
    $info = New-Object Microsoft.EnterpriseManagement.ConnectorFramework.ConnectorInfo;
 
    $info.Description = "...";
    $info.DisplayName = $ConnectorName;
    $info.Name = $ConnectorName;

    $connector = $icfm.Setup($info, $connectorGuid);
 
    $connector.Initialize();
}
elseif ($action -eq "UninstallConnector")
{    
    $mg = New-Object Microsoft.EnterpriseManagement.ManagementGroup($ManagementServer);
    $icfm = $mg.ConnectorFramework;
    $connector = $icfm.GetConnector($connectorGuid);
                        
    $subscriptions = $icfm.GetConnectorSubscriptions();
 
    foreach ($subscription in $subscriptions)
    {
        if ($subscription.MonitoringConnectorId -eq $connectorGuid)
        {
            $icfm.DeleteConnectorSubscription($subscription);
        }
    }
 
    $connector.Uninitialize();
    $icfm.Cleanup($connector);
}

exit 0;
