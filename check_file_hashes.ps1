$intOK = 0;
$intWarning = 1;
$intCritical = 2;
$intUnknown = 3;
$errcode = $intUnknown;
$output = "";

$failtrigger = $false

$app1PathToBinary = '\\srv1.contoso.com\WebServices\'
$app2PathToBinary = '\\srv2.contoso.com\WebServices\'
function getmd5hash ($pathToFile) {
    $md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
    $fileToHash = [System.IO.File]::Open($pathToFile,'Open','Read','ReadWrite');
    $hashOfFile = [String]::Join("", ($md5.ComputeHash($fileToHash) | % {$_.ToString("x2")}))
    $fileToHash.Dispose()
    return [string]$hashOfFile
}

try
{
$ErrorActionPreference = "Stop";

if ((Test-Path $app1PathToBinary) -and (Test-Path $app2PathToBinary)) {
    $arrayOfApp1Binary = Get-ChildItem $app1PathToBinary | where {$_.Name -match ".+\.dll$" -or $_.Name -match ".+\.exe$"}
    $arrayOfApp2Binary = Get-ChildItem $app2PathToBinary | where {$_.Name -match ".+\.dll$" -or $_.Name -match ".+\.exe$"}
    
    foreach ($binFile in $arrayOfApp1Binary) {
        $binFile2 = $arrayOfApp2Binary | where {$_.Name -eq $binFile.Name}
        if (!$binFile2) {
            $failtrigger = $true
            $output += "$($binFile.Name) - no corresponding file; "
        } else {
            $hash1 = getmd5hash $binFile.FullName
            $hash2 = getmd5hash $binFile2.FullName
            if ($hash1 -eq $hash2) {
                $output += "$($binFile.Name) - OK; "
            } else {
                $failtrigger = $true
                $output += "$($binFile.Name) - hashes did not match; "
            }
        }
    }

    if ($failtrigger) {
        $errcode = $intCritical
    } else {
        $errcode = $intOK
    }

} else {
    $errcode = $intCritical
    $output = 'Could not access application folder!'
}
}
catch
{
	$errcode = $intCritical
	$output =  $_.Exception.Message;
}


write-host $output;
exit $errcode;
