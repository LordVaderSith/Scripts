#Set variables for dependency files
date 
$registries_HKLM = Get-Content -path regquery_HKLM.txt
$registries_HKU = Get-Content -path regquery_HKU.txt
if (Get-Item regquery_HKLM.txt) {
	#Continue running
} else {
	Write-Host -ForegroundColor Red "ERROR!!! Missing the file 'regquery_HKLM' in the working directory ${pwd}"
	Write-Host -ForegroundColor Red "Press ANY KEY to exit"
	Read-Host
	exit
}
if (Get-Item regquery_HKU.txt) {
	#Continue running
} else {
	Write-Host -ForegroundColor Red "ERROR!!! Missing the file 'regquery_HKU' in the working directory ${pwd}"
	Write-Host -ForegroundColor Red "Press ANY KEY to exit"
	Read-Host
	exit
}

#Set variables for output files
New-Item -Path C:\Windows\Temp\survey_output -Type Directory
$regOutFile = "C:\Windows\Temp\survey_output\resultsRegistry.txt"
$mainOutFile = "C:\Windows\Temp\survey_output\results.txt"
$dirwalkFile = "C:\Windows\Temp\survey_output\resultsDirwalk.txt"
$ADSOutFile = "C:\Windows\Temp\survey_output\resultsADS.txt"

#Sets the console screen size and gather intial infomation
[System.Console]::BufferWidth=500
Write-Output "" > $mainOutFile
date >> $mainOutFile
systeminfo >> $mainOutFile

#Check to see if the script is running under Administrator credentials
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
Write-Output "Are you running as Administrator?" >> $mainOutFile
$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) >> $mainOutFile
Write-Output "" >> $mainOutFile

#Enumerate Custom registries
Write-Output "####Checking Local Machine Registries####" >> $regOutFile
Write-Host -ForegroundColor Green "[Step 1 of 9] ####Checking Local Machine Registries####"
foreach($registry in $registries_HKLM){
    	Write-Output $registry >> $regOutFile 2> $null
        reg query $registry /s >> $regOutFile 2> $null
        Write-Output "------------------------------------------------------------------------------" >> $regOutFile
}
Write-Output "------------------------------------------------------------------------------" >> $regOutFile
Write-Output "------------------------------------------------------------------------------" >> $regOutFile
Write-Output "-----------------------------------BREAK--------------------------------------" >> $regOutFile
Write-Output "" >> $regOutFile
Write-Output "" >> $regOutFile
Write-Output "" >> $regOutFile

#Get Individual Users registry keys
Write-Output "####Checking Individual User Registries####" >> $regOutFile
Write-Host -ForegroundColor Green "[Step 2 of 9] ####Checking Individual User Registries####"
foreach($registry in $registries_HKU){
    	Write-Output $registry >> $regOutFile 2> $null
        reg query HKU | foreach {
			$temp_reg_query=$_+$registry
			reg query $temp_reg_query /s >> $regOutFile 2> $null
		}
        Write-Output "------------------------------------------------------------------------------" >> $regOutFile
}
Write-Output "------------------------------------------------------------------------------" >> $regOutFile
Write-Output "------------------------------------------------------------------------------" >> $regOutFile
Write-Output "-----------------------------------BREAK--------------------------------------" >> $regOutFile
Write-Output "" >> $regOutFile
Write-Output "" >> $regOutFile
Write-Output "" >> $regOutFile

#Survey volitale information
Write-Output "####Checking For Volatile Information####" >> $mainOutFile
Write-Host -ForegroundColor Green "[Step 3 of 9] ####Checking For Volatile Information####"
ipconfig /all >> $mainOutFile
netstat /anobp tcp >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
wmic process get Name,processid,parentprocessid,executablepath,CommandLine >> $mainOutFile
Get-Process|Format-List -Property Name,FileVersion,Id,PriorityClass,HandleCount,Path,Description,PrivilegedProcessorTime,SessionId,StartTime,UserProcessorTime,VirtualMemorySize64 >> $mainOutFile
tasklist /m >> $mainOutFile
tasklist /svc >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
driverquery >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Get-SmbShare >> $mainOutFile
Get-SmbMapping >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
schtasks /query /fo:list /v >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Write-Output "-----------------------------------BREAK--------------------------------------" >> $mainOutFile
Write-Output "" >> $mainOutFile
Write-Output "" >> $mainOutFile
Write-Output "" >> $mainOutFile

#Get users information
Write-Output "####Checking For Users Information####" >> $mainOutFile
Write-Host -ForegroundColor Green "[Step 4 of 9] ####Checking For Users Information####"
Get-LocalGroupMember -Group administrators >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Get-LocalUser >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
wmic useraccount get name,sid >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Write-Output "-----------------------------------BREAK--------------------------------------" >> $mainOutFile
Write-Output "" >> $mainOutFile
Write-Output "" >> $mainOutFile
Write-Output "" >> $mainOutFile

#Search for any users being created/deleted
Write-Output "####Checking For User Account Creation/Deletion Audit Logs####" >> $mainOutFile
Write-Host -ForegroundColor Green "[Step 5 of 9] ####Checking For User Account Creation/Deletion Audit Logs####"
Get-WinEvent -FilterHashtable @{ LogName="Security"; Id="4720" }|Select-Object TimeCreated,Id,ProcessId,Task,Message|ConvertTo-Csv >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Get-WinEvent -FilterHashtable @{ LogName="Security"; Id="4726" }|Select-Object TimeCreated,Id,ProcessId,Task,Message|ConvertTo-Csv >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Write-Output "-----------------------------------BREAK--------------------------------------" >> $mainOutFile
Write-Output "" >> $mainOutFile
Write-Output "" >> $mainOutFile
Write-Output "" >> $mainOutFile

#Discover the time/date range of the Security Event Logs
Write-Output "####Checking For Audit Logs Approximate Time Range####" >> $mainOutFile
Write-Host -ForegroundColor Green "[Step 6 of 9] ####Checking For Audit Logs Approximate Time Range####"
$timestamp_array=Get-WinEvent -FilterHashtable @{ LogName="Security"; Id="5379" }|Select-Object TimeCreated |ConvertTo-Csv
Write-Output "###Start Time###" >> $mainOutFile
$timestamp_array[$timestamp_array.Length-1] >> $mainOutFile
Write-Output "###End Time###" >> $mainOutFile
$timestamp_array[2] >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Write-Output "------------------------------------------------------------------------------" >> $mainOutFile
Write-Output "-----------------------------------BREAK--------------------------------------" >> $mainOutFile
Write-Output "" >> $mainOutFile
Write-Output "" >> $mainOutFile
Write-Output "" >> $mainOutFile

#Enumerate Custom directories
Write-Host -ForegroundColor Green "[Step 7 of 9] ####Dir Walk####"
Write-Output "" > $dirwalkFile
(Get-PSDrive -PSProvider FileSystem).Name | foreach {Get-ChildItem -Recurse -Force -Path $_":\" 2> $null | Select-Object Mode,LastWriteTime,CreationTime,LastAccessTime,Length,Name|Format-Table -Wrap} >> $dirwalkFile

#Alternate Data Stream check
Write-Host -ForegroundColor Green "[Step 8 of 9] ####Checking For Alternate Data Streams Information####"
Write-Output "" > $ADSOutFile
Get-ChildItem -Force -Recurse "C:\" 2> $null| % { Get-Item $_.FullName -stream * 2> $null} | where stream -ne ':$Data' | where stream -ne 'Zone.Identifier' >> $ADSOutFile

#Zip everything up
Write-Host -ForegroundColor Green "[Step 9 of 9] ####Creating Zip File####"
date >> $mainOutFile
Compress-Archive -Path C:\Windows\Temp\survey_output\ -DestinationPath C:\Windows\Temp\results_survey.zip -Force
$file_location=Get-ChildItem C:\Windows\Temp\results_survey.zip
Write-Host -ForegroundColor Green "File is located at:"
Write-Host -ForegroundColor Cyan "$file_location"
Start-Sleep 5
Remove-Item C:\Windows\Temp\survey_output\ -Recurse -Force

Write-Host -ForegroundColor Green "####DONE!!!####"
date
Write-Host -ForegroundColor Yellow "Press ANY KEY to finish [if window closes, please ensure you opened an Administrator window and run again...]"
Read-Host