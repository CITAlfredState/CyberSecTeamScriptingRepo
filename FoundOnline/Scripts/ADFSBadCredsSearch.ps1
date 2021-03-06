PARAM ($PastDays = 1, $PastHours)
#************************************************
# ADFSBadCredsSearch.ps1
# Version 1.0
# Date: 6-20-2016
# Author: Tim Springston [MSFT]
# Description: This script will parse the ADFS server's (not proxy) security ADFS
#  for events which indicate an incorrectly entered username or password. The script can specify a
#  past period to search the log for and it defaults to the past 24 hours. Results will be placed into a CSV for 
#  review of UPN, IP address of submitter, and timestamp.
#************************************************

cls
if ($PastHours -gt 0)
	{$PastPeriod = (Get-Date).AddHours(-($PastHours))}
	else
		{$PastPeriod = (Get-Date).AddDays(-($PastDays))	}
$Outputfile = $Pwd.path + "\BadCredAttempts.csv"
$CS = get-wmiobject -class win32_computersystem
$Hostname = $CS.Name + '.' + $CS.Domain
$Instances = @{}
$OSVersion = gwmi win32_operatingsystem
[int]$BN = $OSVersion.Buildnumber 
if ($BN -lt 9200){$ADFSLogName = "AD FS 2.0/Admin"}
	else {$ADFSLogName = "AD FS/Admin"}

$Users = @()
$IPAddresses = @()
$Times = @()
$AllInstances = @()
Write-Host "Searching event log for bad credential events..."
if ($BN -ge 9200) {Get-Winevent  -FilterHashTable @{LogName= "Security"; StartTime=$PastPeriod; ID=411} -ErrorAction SilentlyContinue | Where-Object  {$_.Message -match "The user name or password is incorrect"} |  % {
	$Instance = New-Object PSObject
	$UPN = $_.Properties[2].Value
	$UPN = $UPN.Split("-")[0]
	$IPAddress = $_.Properties[4].Value
	$Users += $UPN
	$IPAddresses += $IPAddress
	$Times += $_.TimeCreated
	add-member -inputobject $Instance -membertype noteproperty -name "UserPrincipalName" -value $UPN
	add-member -inputobject $Instance -membertype noteproperty -name "IP Address" -value $IPAddress
	add-member -inputobject $Instance -membertype noteproperty -name "Time" -value ($_.TimeCreated).ToString()
	$AllInstances += $Instance
	$Instance = $null
	}
}


$AllInstances | select * | Export-Csv -Path $Outputfile -append -force -NoTypeInformation 
Write-Host "Data collection finished. The output file can be found at $outputfile`."
$AllInstances = $null
