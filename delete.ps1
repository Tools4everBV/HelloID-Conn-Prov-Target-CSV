#################################################
# HelloID-Conn-Prov-Target-CSV-Delete
# Delete csv row
# PowerShell V2
#################################################
# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
switch ($actionContext.Configuration.isDebug) {
    $true { $VerbosePreference = "Continue" }
    $false { $VerbosePreference = "SilentlyContinue" }
}
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region functions
#endregion functions

#region account
# Define correlation
$correlationField = "EmployeeId"
$correlationValue = $actionContext.References.Account

$account = [PSCustomObject]$actionContext.Data
#endRegion account

try {
    #region Verify account reference
    $actionMessage = "verifying account reference"
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw "The account reference could not be found"
    }
    #endregion Verify account reference

    #region Import CSV data
    $actionMessage = "importing data from CSV file at path [$($actionContext.Configuration.CsvPath)]"
   
    $csvContent = $null
    $csvContent = Import-Csv -Path $actionContext.Configuration.CsvPath -Delimiter $actionContext.Configuration.Delimiter -Encoding $actionContext.Configuration.Encoding
   
    # Group on correlation field to match employee to CSV row(s)
    $csvContentGrouped = $csvContent | Group-Object -Property $correlationField -AsString -AsHashTable

    Write-Verbose "Imported data from CSV file at path [$($actionContext.Configuration.CsvPath)]. Result count: $(($csvContent | Measure-Object).Count)"
    #endregion Import CSV data

    if ($actionContext.CorrelationConfiguration.Enabled -eq $true) {
        #region Get current row for person
        $actionMessage = "querying CSV row where [$($correlationField)] = [$($correlationValue)]"
       
        $currentRow = $null
        if ($csvContentGrouped -ne $null) {
            $currentRow = $csvContentGrouped["$($correlationValue)"]
        }

        Write-Verbose "Queried CSV row where [$($correlationField)] = [$($correlationValue)]. Result count: $(($currentRow | Measure-Object).Count)"
        #endregion Get current row for person
    }

    #region Account
    #region Calulate action
    $actionMessage = "calculating action"
    if (($currentRow | Measure-Object).count -eq 1) {
        $action = "Delete"
    }
    elseif (($currentRow | Measure-Object).count -gt 1) {
        $action = "MultipleFound"
    }
    elseif (($currentRow | Measure-Object).count -eq 0) {
        $action = "NotFound"
    }
    #endregion Calulate action

    #region Process
    switch ($action) {
        "Delete" {
            #region Delete csv row
            $actionMessage = "deleting row from CSV"

            #region Create custom updated csv object without current row for person
            $updatedCsvContent = $null
            $updatedCsvContent = [System.Collections.ArrayList](, ($csvContent | Where-Object { $_ -notin $currentRow }))
            #endregion Create custom updated csv object without current row for person

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
                Write-Verbose "SplatParams: $($exportCsvSplatParams | ConvertTo-Json)"

                $updatedCsv = $updatedCsvContent | Foreach-Object { $_ } | Export-Csv @exportCsvSplatParams

                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        # Action  = "" # Optional
                        Message = "Deleted row from CSV [$($exportCsvSplatParams.Path)] with AccountReference: $($outputContext.AccountReference | ConvertTo-Json)."
                        IsError = $false
                    })
            }
            else {
                Write-Warning "DryRun: Would delete row from CSV [$($exportCsvSplatParams.Path)] where [$($correlationField)] = [$($correlationValue)]."
            }
            #endregion Delete csv row

            break
        }

        "MultipleFound" {
            #region Multiple accounts found
            $actionMessage = "deleting row from CSV"

            # Throw terminal error
            throw "Multiple CSV rows found where [$($correlationField)] = [$($correlationValue)]. Please correct this so the persons are unique."
            #endregion Multiple accounts found

            break
        }

        "NotFound" {
            #region No account found
            $actionMessage = "skipping deleting row from CSV"

            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    # Action  = "" # Optional
                    Message = "Skipped deleting deleting row from CSV with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Reason: No CSV row found where [$($correlationField)] = [$($correlationValue)]. Possibly indicating that it could be deleted, or not correlated."
                    IsError = $true
                })
            #endregion No account found

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
}