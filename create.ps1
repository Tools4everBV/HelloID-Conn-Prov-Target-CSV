#################################################
# HelloID-Conn-Prov-Target-CSV-Create
# Create and update or correlate to csv row
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
#endregion functions

#region account
# Define correlation
$correlationField = $actionContext.CorrelationConfiguration.accountField
$correlationValue = $actionContext.CorrelationConfiguration.accountFieldValue

$account = $actionContext.Data
#endRegion account

try {
    #region Verify correlation configuration and properties
    $actionMessage = "verifying correlation configuration and properties"

    if ($actionContext.CorrelationConfiguration.Enabled -eq $true) {
        if ([string]::IsNullOrEmpty($correlationField)) {
            throw "Correlation is enabled but not configured correctly."
        }

        if ([string]::IsNullOrEmpty($correlationValue)) {
            throw "The correlation value for [$correlationField] is empty. This is likely a mapping issue."
        }
    }
    else {
        throw "Correlation is disabled. However, this connector requires correlation, as it's designed to support only one object per person."
    }
    #endregion Verify correlation configuration and properties

    #region Import CSV data
    $actionMessage = "importing data from CSV file at path [$($actionContext.Configuration.CsvPath)]"

    # Only load csv file when it exists
    $csvContent = $null
    if (Test-Path $actionContext.Configuration.CsvPath) {

        $csvContent = Import-Csv -Path $actionContext.Configuration.CsvPath -Delimiter $actionContext.Configuration.Delimiter -Encoding $actionContext.Configuration.Encoding
    }

    # Group on correlation field to match employee to CSV row(s)
    $csvContentGrouped = $csvContent | Group-Object -Property $correlationField -AsString -AsHashTable

    Write-Information "Imported data from CSV file at path [$($actionContext.Configuration.CsvPath)]. Result count: $(($csvContent | Measure-Object).Count)"
    #endregion Import CSV data

    #region Get current row for person
    $actionMessage = "querying CSV row where [$($correlationField)] = [$($correlationValue)]"

    $currentRow = $null
    if ($null -ne $csvContentGrouped) {
        $currentRow = $csvContentGrouped["$($correlationValue)"]
    }

    Write-Information "Queried CSV row where [$($correlationField)] = [$($correlationValue)]. Result count: $(($currentRow | Measure-Object).Count)"
    #endregion Get current row for person

    #region Account
    #region Calulate action
    $actionMessage = "calculating action"
    if (($currentRow | Measure-Object).count -eq 0) {
        $action = "Create"
    }
    elseif (($currentRow | Measure-Object).count -eq 1) {
        $action = "Correlate"
    }
    elseif (($currentRow | Measure-Object).count -gt 1) {
        $action = "MultipleFound"
    }
    #endregion Calulate action

    #region Process
    switch ($action) {
        "Create" {
            #region Create csv row
            $actionMessage = "creating row in CSV"

            #region Create custom updated csv object
            $updatedCsvContent = $null
            $updatedCsvContent = [System.Collections.ArrayList](, ($csvContent))
            #endregion Create custom updated csv object

            #region Add new CSV row to custom updated csv object
            [void]$updatedCsvContent.Add($account)
            #endregion Add new CSV row to custom updated csv object

            #region Export updated CSV object
            $exportCsvSplatParams = @{
                Path              = $actionContext.Configuration.CsvPath
                Delimiter         = $actionContext.Configuration.Delimiter
                Encoding          = $actionContext.Configuration.Encoding
                NoTypeInformation = $true
                ErrorAction       = "Stop"
                Verbose           = $false
            }

            if (-Not($actionContext.DryRun -eq $true)) {
                if (Test-Path $actionContext.Configuration.CsvPath) {
                    $null = $updatedCsvContent | Foreach-Object { $_ } | Export-Csv @exportCsvSplatParams
                }
                else {
                    $account | Export-Csv @exportCsvSplatParams                    
                }

                #region Set AccountReference
                $outputContext.AccountReference = "$($correlationValue)"
                #endregion Set AccountReference

                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        # Action  = "" # Optional
                        Message = "Created row in CSV [$($exportCsvSplatParams.Path)] where [$($correlationField)] = [$($correlationValue)] with AccountReference: $($outputContext.AccountReference | ConvertTo-Json)."
                        IsError = $false
                    })
            }
            else {
                Write-Warning "DryRun: Would create row in CSV [$($exportCsvSplatParams.Path)] where [$($correlationField)] = [$($correlationValue)]."
            }
            #endregion Create csv row

            break
        }

        "Correlate" {
            #region Correlate account
            $actionMessage = "correlating to CSV row"

            $outputContext.AccountReference = "$($correlationValue)"
            $outputContext.Data = $currentRow

            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = "CorrelateAccount"
                    Message = "Correlated to CSV row with AccountReference: $($outputContext.AccountReference | ConvertTo-Json) on [$($correlationField)] = [$($correlationValue)]."
                    IsError = $false
                })

            $outputContext.AccountCorrelated = $true
            #endregion Correlate account

            break
        }

        "MultipleFound" {
            #region Multiple accounts found
            $actionMessage = "correlating to CSV row"

            # Throw terminal error
            throw "Multiple CSV rows found where [$($correlationField)] = [$($correlationValue)]. Please correct this so the persons are unique."
            #endregion Multiple accounts found

            break
        }
    }
    #endregion Process
    #endregion Account
}
catch {
    $ex = $PSItem
    $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    Write-Warning "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"

    $outputContext.AuditLogs.Add([PSCustomObject]@{
            # Action  = "" # Optional
            Message = $auditMessage
            IsError = $true
        })
}
finally {
    # Check if auditLogs contains errors, if no errors are found, set success to true
    if ($outputContext.AuditLogs.IsError -contains $true) {
        $outputContext.Success = $false
    }
    else {
        $outputContext.Success = $true
    }

    # Check if accountreference is set, if not set, set this with default value as this must contain a value
    if ([String]::IsNullOrEmpty($outputContext.AccountReference) -and ($actionContext.DryRun -eq $true)) {
        $outputContext.AccountReference = "DryRun: Currently not available"
    }
}