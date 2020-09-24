using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "Powershell iAlertHttptrigger function processed a request."

$alert = $Request.body

if ($alert) {
    $status = [HttpStatusCode]::OK
    

    $body = $alert | ConvertTo-json
    $severity = $alert.data.essentials.severity
    $alertId = $alert.data.essentials.originAlertId 
    #Write-Information -MessageData "AlertId: $alertId "

    $alertRule = $alert.data.essentials.alertRule
    #Write-Information -MessageData "AlertRule: $alertRule "

    if($severity -eq "Sev4"){
        #Write-Information -MessageData "Severity: $severity received "
    
        $Count = 0
        $MaxReturn = 10000
        $StorageAccountName = $env:StorageAccountName
        $FileSystemName = $env:Filesystem

        $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount 
        $cn = Get-AzDataLakeGen2ChildItem -Context $ctx -FileSystem $FileSystemName -Path "/" -Recurse -MaxCount $MaxReturn -FetchProperty  | where {$_.Path -Match 'failed' -and !$_.IsDirectory} 
        #Write-Information -MessageData " Deleting one file at a time -->  $($cn[1].Path)"
        $cn[1] | Remove-AzDataLakeGen2Item -Force ##| Out-Null

        #Sample action :delete one file at a time a sample action.
        Write-Information -MessageData "AlertId: $alertId ,AlertRule: $alertRule ,Severity: $severity, deleted file: $($cn[1].Path)"
    }
    else {
        Write-Information -MessageData "Severity: not identified"
    }
    
}
else {
    
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass something in the request body."
    ##Write-Information -MessageData $body
    Write-Output "~~~~~~~~~~~~~~~~~~~~~"
    Write-Output $body
    Write-Output "~~~~~~~~~~~~~~~~~~~~~"
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})