#Initialize default properties
$p = $person | ConvertFrom-Json;
$auditMessage = "For person $($p.DisplayName) password writeback";
$success = $false;
$filePath = "\\server\c$\HelloID\StudentPasswords.csv";

$mutexName = 'helloIDWriteback'
$mutex = New-Object 'Threading.Mutex' $false, $mutexName
		
try{
	[void]$mutex.WaitOne(6000);
	#add new row
	$newRow = New-Object -TypeName PsObject -Property (@{ID=$p.ExternalId
														Email=$p.Accounts.ActiveDirectory.Mail
                                                      })
    if(-Not($dryRun -eq $True)){  
	    $newRow | Export-Csv -NoTypeInformation -Path $filePath -Append
    }
    $success = $true;
    $aRef = $newRow.Email;
    $account = $newRow;
}
finally{
	$mutex.ReleaseMutex()
}

#build up result
$result = [PSCustomObject]@{
    Success= $success;
    AccountReference= $aRef;
    AuditDetails=$auditMessage;
    Account= $account;
};
  
Write-Output $result | ConvertTo-Json -Depth 10;
