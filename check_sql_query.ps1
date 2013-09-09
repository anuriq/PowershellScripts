###########################
#
# Created by anuriq. 2012.
#
###########################

$intOK = 0;
$intWarning = 1;
$intCritical = 2;
$intUnknown = 3;
$errcode = $intCritical;
$output = "";

$Database = "YOUR_DATABASE"
$ServerInstance = "DB_SERVER"
#If you have mirroring, use Failover Partner
#$FailoverPartner = "DB_SERVER2"
$query = @"
SELECT * FROM INFORMATION_SCHEMA.TABLES
"@;
$queryTimeout = 20

#Connection string for Standalone SQL server or Cluster
$ConnectionString = "Server=$ServerInstance; Database=$Database; Integrated Security=True; Network Library=dbmssocn";
#Connection string for mirroring failover configured SQL servers
$ConnectionString = "Server=$ServerInstance; Failover Partner=$FailoverPartner; Database=$Database; Integrated Security=True; Network Library=dbmssocn";
#If you use SQL logins, they are specified in a connection string.
#For more info, check http://msdn.microsoft.com/en-us/library/system.data.sqlclient.sqlconnection.connectionstring.aspx

try
{
    $ErrorActionPreference = "Stop";

    $conn = new-object System.Data.SqlClient.SQLConnection;
    $conn.ConnectionString = $ConnectionString;
    $conn.Open();
    $cmd=new-object system.Data.SqlClient.SqlCommand($query,$conn);
    $cmd.CommandTimeout=$queryTimeout;
    #For NONQUERY statements like UPDATE, INSERT, etc.
    #$cmd.ExecuteNonQuery() | Out-Null
    #For SELECT statements
    $ds=New-Object system.Data.DataSet;
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd);
    [void]$da.fill($ds);

    $conn.Close();

    #Now, your result is in a $ds.Tables. It is a collection of tables, in most cases there is only one table - $ds.Tables[0]
    #$ds.Tables[0] is a two-dimensional array, you can select by indexes, or column names. For example, I ask for first table name
    $table_name = $ds.Tables[0].Rows[0][2] 
    #or
    $table_name = $ds.Tables[0].Rows[0]['TABLE_NAME'] 
    #for a quantity of rows, use:
    $rowscount = $ds.Tables[0].Rows.Count

    #Here you can check your output for any parameters, and then

    $errcode = $intOK;
    $output = "All is good."
}
catch
{
	$errcode = $intCritical
	$output =  $_.Exception.Message;
}


write-host $output;
exit $errcode;
