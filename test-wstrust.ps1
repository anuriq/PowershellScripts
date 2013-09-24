$intOK = 0
$intWarning = 1
$intCritical = 2
$intUnknown = 3
$errcode = $intUnknown
$output = "Unknown error."

$formRequest = @"
POST_MESSAGE_GENERATED_BY_SITE_TO_WSTRUST
"@

$myTargetSite = "https://mysite.contoso.com";
$myTargetSiteLoginForm = "https://mysite.contoso.com/?logonSessionData=MySite&returnUrl=en%2Findex.html%3Fv2";
$myTargetSiteRequestedPage = "https://mysite.contoso.com/profile/index.html";
$myWsTrustServer = "https://wstrust.contoso.com";
$myWsTrustServerLogon = "https://wstrust.contoso.com/Logon.aspx";

try
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null

    ######################## 1st REQUEST #########################
    $httpWebRequest = [System.Net.WebRequest]::Create($myWsTrustServerLogon)

    $httpWebRequest.Proxy = $null;
    #Adding custom headers - if used.
    $httpWebRequest.Headers.Add("Origin",$myTargetSite);
    $httpWebRequest.Headers.Add("Accept-Language",'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4');
    $httpWebRequest.Headers.Add("Accept-Charset",'windows-1251,utf-8;q=0.7,*;q=0.3');
    $httpWebRequest.Referer = $myTargetSiteLoginForm;
    $httpWebRequest.ContentType = 'application/x-www-form-urlencoded';
    $httpWebRequest.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";

    $httpWebRequest.Method = "POST";
    #POST MESSAGE
    $utf8encoding = New-Object System.Text.UTF8Encoding;
    $byteMessage = $utf8encoding.GetBytes($formRequest);
    $requestStream = $httpWebRequest.GetRequestStream();
    $requestStream.Write($byteMessage,0,$byteMessage.Length);
    $requestStream.Close();

    #GET response
    $response = $httpWebRequest.GetResponse();
    #Saving response from server
    $responseStream = $response.GetResponseStream();
    $result = ([System.IO.StreamReader]($responseStream)).ReadToEnd();
    $responseStream.Close();

    $xmlresult = [xml]$result
    $newFormRequest = 'wa=' + [System.Web.HttpUtility]::UrlEncode($xmlresult.html.body.form.input[0].value.ToString());
    $newFormRequest += '&wresult=' + [System.Web.HttpUtility]::UrlEncode($xmlresult.html.body.form.input[1].value.ToString());
    $newFormRequest += '&wctx=' + [System.Web.HttpUtility]::UrlEncode($xmlresult.html.body.form.input[2].value.ToString());

    ######################## 2nd REQUEST #########################
    $httpWebRequest2 = [System.Net.WebRequest]::Create($myTargetSite);

    $httpWebRequest2.Proxy = $null;
    $httpWebRequest2.AllowAutoRedirect = $false;
    #Adding custom headers - if used.
    $httpWebRequest2.Headers.Add("Origin",$myWsTrustServer);
    $httpWebRequest2.Headers.Add("Accept-Language",'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4');
    $httpWebRequest2.Headers.Add("Accept-Charset",'windows-1251,utf-8;q=0.7,*;q=0.3');
    $httpWebRequest2.Referer = $myWsTrustServerLogon;
    $httpWebRequest2.ContentType = 'application/x-www-form-urlencoded';
    $httpWebRequest2.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";

    $httpWebRequest2.Method = "POST";
    $utf8encoding = New-Object System.Text.UTF8Encoding;
    $byteMessage = $utf8encoding.GetBytes($newFormRequest);
    $requestStream = $httpWebRequest2.GetRequestStream();
    $requestStream.Write($byteMessage,0,$byteMessage.Length);
    $requestStream.Close();

    #GET response
    $response2 = $httpWebRequest2.GetResponse();
    $CookieHeader = $response2.Headers['Set-Cookie'];

    ######################## 3rd REQUEST #########################
    $httpWebRequest3 = [System.Net.WebRequest]::Create($myTargetSiteRequestedPage);

    $httpWebRequest3.Proxy = $null;
    #Adding custom headers - if used.
    $httpWebRequest3.Headers.Add("Accept-Language",'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4');
    $httpWebRequest3.Headers.Add("Accept-Charset",'windows-1251,utf-8;q=0.7,*;q=0.3');
    #for all requests from now on use cookie information
    $httpWebRequest3.Headers.Add("Cookie",$CookieHeader);
    $httpWebRequest3.Referer = $myWsTrustServerLogon;
    $httpWebRequest3.ContentType = 'application/x-www-form-urlencoded';
    $httpWebRequest3.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";

    $response3 = $httpWebRequest3.GetResponse();
    $responseStream = $response3.GetResponseStream();
    $result3 = ([System.IO.StreamReader]($responseStream)).ReadToEnd();
    $responseStream.Close();

    #we check received html for pattern matching 
    if ($result3 -match "PATTERN") {
	    $errcode = $intOK
	    $output = "Response is OK. String Exit found."
    } else {
	    if ($result) {
		    $errcode = $intWarning
		    $output = "Response is unexpected. No string - Exit."
	    } else {
		    $errcode = $intCritical
		    $output = "No response."
	    }
    }

} #end of try block
catch
{
    $errcode = $intCritical
    $output =  $_.Exception.Message
}

write-host $output
exit $errcode
