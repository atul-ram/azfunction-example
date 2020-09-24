# Input bindings are passed in via param block.
param($Timer)

$Count = 0
$MaxReturn = 10000

$StorageAccountName = $env:StorageAccountName
$FileSystemName = $env:Filesystem

$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

$Object = @()

$cn = Get-AzDataLakeGen2ChildItem -Context $ctx -FileSystem $FileSystemName -Path "/" -Recurse -MaxCount $MaxReturn -FetchProperty  |  where { !$_.IsDirectory} |  Select-Object -Property Path

foreach ($item in $cn) {
    
    $a = ($item.Path.Split('/')[0])
    $b =  ($item.Path.Split('/')[1])

    $Object += New-Object PSObject -Property @{
        one = $a
        two = $b
    }

} 

$csvString = $Object | group-object -Property one | Select-Object -Property Count,Name | ConvertTo-json

##$csvString


# Replace with your Workspace ID
$CustomerId = $env:WorkspaceId

# Replace with your Primary Key
$SharedKey = $env:WorkspaceSharedKey

# Specify the name of the record type that you'll be creating
$LogType = "MyCustomLog"

# You can use an optional field to specify the timestamp from the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
$TimeStampField = ""

# Create two records with the same set of properties to create
$json = $csvString

# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}


# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}

# Submit the data to the API endpoint
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
