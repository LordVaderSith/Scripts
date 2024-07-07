#This script is designed to identify any missing log entries on a Windows system by parsing thru all the logs.
#For the best results, run as an Administrator.
#For non-local logs use "-UseFolder "EVTXLogFile.evtx" otherwise.
#Ensure the EVTX file is not exported/saved with display information. Otherwise you'll get the following error: "Error: Get-WinEvent : The specified publisher name is invalid".
#Author: CW2 Smith, Terrance L.
#Contributions: SFC Wolownik, Peter
#Powershell v5.1

param (
	[Parameter()]
	[string]$UseFolder
)

#Set global variables
$start_num=0
$record_num=0
$count1=0
$count2=0
$UseFolderBoolean=$false
$EVTXFolderPath = ""

Write-Host -ForegroundColor DarkGreen "Starting Checks..."
#Check to see if the script is running under Administrator credentials
$currentPrincipal = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($currentPrincipal -eq $true) {
	#Do nothing
} else {
	Write-Host -ForegroundColor Yellow "CAUTION!! You are NOT Admin currently. Some logs may not be accessible and will show as 'empty'."
}

#Uses the parameter -UseFolder to set the custom path as a string with a trailing "\".
if ($UseFolder -ne '') {
	$UseFolderBoolean = $true
	$EVTXFolderPath = $UseFolder
	$EVTXFolderPath += "\"
}

#This sets the varible for which Eventlogs are being examined. Local or an EVTX file.
#$UseFolder = $false  # Default value
#$EVTXFolderPath = ""
#
##Check if the -UseFolder switch is present
#if ($args -contains "-UseFolder") {
#    $UseFolder = $true
#    $EVTXFolderPath = $args[$args.IndexOf("-UseFolder") + 1]
#	$EVTXFolderPath += "\"
#}
#if ($UseFolderBoolean) {
#   # $UseFolder = $true
#    $EVTXFolderPath = $UseFolder
#	$EVTXFolderPath += "\"
#}

#Parse thru the event logs located in a specified directory
function Parse-ExternalLogs { 
	(Get-ChildItem $EVTXFolderPath).Name | foreach {
		$temp1=$EVTXFolderPath + $_
		$count1=0
		$count2=0
		Write-Host -ForegroundColor Green "Checking $_ Log"
		if ((Get-WinEvent -Path $temp1)[1] -eq $null) {						#Check to see the Log is empty and skips over it
			Write-Host -ForegroundColor Blue "---> $temp1 is empty"
			$count2++
		} else {
			Get-WinEvent -Path $temp1|Select-Object RecordId|ConvertTo-Csv | foreach {
				Count-ID $_
				#try {
				#	
				#	#Establish the current Record ID number: this number reflects what the Record ID ACTUALLY is
				#	$record_num=[int]$_.Trim('"')
				#	if ($record_num.GetType().Name -ne "Int32") {
				#		Write-Host -ForegroundColor Red "CUSTOM ERROR!!! I should have a number but instead I recieved:"
				#		Write-Host -ForegroundColor Blue "$record_num"
				#		continue
				#	}
				#	
				#	#Establish the number to start comparing the Record ID to: this number should reflect what the Record ID SHOULD be
				#	if ($count1 -eq 0) {
				#		$start_num=[int]$_.Trim('"')
				#		$count1++
				#	}
				#	if ($start_num -eq $record_num) {
				#		#Do nothing
				#	} else {
				#		$count2++
				#		while ($start_num -ne $record_num) {
				#			Write-Host -ForegroundColor Red "Record ID $start_num is missing!!!"
				#			$start_num--
				#		}
				#	}
				#} catch [System.Management.Automation.RuntimeException] {
				#	#Custom error for trying to convert a non-int into an integer: it is expected to happen on the first two interations of each log.
				#	#Write-Host "Received a non-integer unexpectantly"
				#}
				#
				##Decrement each count by 1
				#$start_num--
			}
		}
		if ($count2 -eq 0) {
			Write-Host -ForegroundColor White "---> No Records are missing"
		}
	}
}

#Parse thru the running system's event logs
function Parse-Logs {
	(Get-EventLog -List).Log | foreach {
		$temp1=$_
		$count1=0
		$count2=0
		Write-Host -ForegroundColor Green "Checking $temp1 Log"
		(Get-EventLog -List | where {$_.Log -eq $temp1}) | where {
			
			if ($_.Entries[0] -eq $null) {						#Check to see the Log is empty and skips over it
				Write-Host -ForegroundColor Blue "---> $temp1 is empty"
				$count2++
			} else {
				Get-WinEvent -FilterHashtable @{LogName=$temp1}|Select-Object RecordId|ConvertTo-Csv | foreach {
					Count-ID $_
				}
			}
		}
		if ($count2 -eq 0) {
			Write-Host -ForegroundColor White "---> No Records are missing"
		}
	}
}

#Performs the actual checks/comparisons of RecordIDs
function Count-ID ($newArg) {
	try {
		#Establish the current Record ID number: this number reflects what the Record ID ACTUALLY is
		$record_num=[int]$newArg.Trim('"')
		if ($record_num.GetType().Name -ne "Int32") {
			Write-Host -ForegroundColor Red "CUSTOM ERROR!!! I should have a number but instead I recieved:"
			Write-Host -ForegroundColor Blue "$record_num"
			continue
		}
		
		#Establish the number to start comparing the Record ID to: this number should reflect what the Record ID SHOULD be
		if ($count1 -eq 0) {
			$start_num=[int]$newArg.Trim('"')
			$count1++
		}
		
		#Perform the comparison: the number should always match, otherwise you have bigger issues!
		if ($start_num -eq $record_num) {
			#Do nothing
		} else {
			$count2++
			while ($start_num -ne $record_num) {
				Write-Host -ForegroundColor Red "Record ID $start_num is missing!!!"
				$start_num--
			}
		}
	} catch [System.Management.Automation.RuntimeException] {
		#Custom error for trying to convert a non-int into an integer: it is expected to happen on the first two interations of each log.
		#Write-Host "Received a non-integer unexpectantly"
	}
	
	#Decrement each count by 1
	$start_num--
}

if ($UseFolder -eq '') {
	Parse-Logs
} else {
	Parse-ExternalLogs
}

Write-Host -ForegroundColor DarkGreen "Script Complete"