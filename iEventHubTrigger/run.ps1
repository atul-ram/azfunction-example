param($eventHubMessages, $TriggerMetadata)

function Get-OperationType
{
    param(
        [AllowNull()]
        $InputObject
    )
    if ( $InputObject -is [array]){
        return "multiple"
    }
    elseif ($InputObject -is [string]){
        return "single"
    }
    else { return "other"}
}


$eventHubMessages.GetEnumerator() | ForEach-Object {

    $correlationId = $($_.records.correlationId)
    $operationName = $($_.records.operationName)
    $clientRequestId = $($_.records.properties.clientRequestId)
    $fileList = @()
    foreach ($item in $_.records.uri) {
        $base = $item.split("?")[0]
        $fileList += $base.split(":443")[1]
    }


    $rawData = $_.records | ConvertTo-Json -Depth 10
    $identity= $_.records.identity | ConvertTo-Json -Depth 10
    $type = Get-OperationType($_.records.operationName)
    
    if($type -eq 'single' -or $type -eq 'multiple'){
        if($_.records.operationName -contains 'PutBlob' -or $_.records.operationName -contains 'DeleteBlob' ){

        $Entity = @{
        partitionKey = "initialUpload"
        rowKey = [guid]::NewGuid().tostring()
        correlationId = $correlationId
        operationName = $operationName
        fileName = $fileList
        clientRequestId = $clientRequestId
        rawData = $rawData
        Identity = $identity
        }
        Push-OutputBinding -Name outputTable -Value $Entity
        }
        else{
            Write-Host "Dropped Entry as, operation is otherthan [PutBlob ,DeleteBlob]"
        }
    }
    
}
