#Version 1.3
#This script compares a files against many at the byte/hex level for similarities matching at the same offset with the same Bytes.
#Instructions: Place the script in a folder. Create a .\malware folder and place all live samples in there. Run the script and follow the prompt: the file must be in the .\malware folder as well.

#Ensures there is a .\malware folder already created. If not, it errors out and tells the user to create it and place all samples in it.
if ((Test-Path "malware") -eq $false) {
	Write-Host -ForegroundColor Red "ERROR: You must have all malware in a folder called .\malware"
	exit
}

#Recieves input for the first file: this is the file that will be compared against all others.
Write-Host "Enter Base File"
$tempfile1a=Read-Host
Write-Host -ForegroundColor Green "Compiling..."
Format-Hex "malware\$tempfile1a" > "$tempfile1a.hex.txt"
$file1=gc "$tempfile1a.hex.txt"

#Initialize global variables.
$file2
$listOfFiles=(Get-ChildItem ".\malware").Name
$num1=6
$num2=6
$offset1=11
$offset2=11
$counterNull1=0
$counterNull2=0
$tempArray=@()
$lockOffsetRow=$false
$offsetRow=@()
$resultsFile="Results_for_$tempfile1a.hex.txt"
Write-Host "" > $resultsFile		#Clears out any left over result files.
$startingOffset=0
$printOutput=$false
$hexLength=8
Get-Date

#Main function
function Get-TwoComparison {
	while ($counterNull1 -lt 2 -or $counterNull2 -lt 2) {
		if ($counterNull1 -gt 2 -or $counterNull2 -gt 2) {
			break
		}
		try {
			if ($offset1 -lt 58) {
				if ($file1[$num1].Substring($offset1,1) -eq $file2[$num2].Substring($offset2,1)) {
					if ($lockOffsetRow -eq $false) {
						#$offsetRow=$file1[$num1].Substring(0,8)
						$offsetRow=$file1[$num1].Substring(0,7)
						$temp1=($offset1 - 11)
						$temp2=[System.Math]::Floor((($offset1 - 11) / 3))
						$temp3=$temp1 - $temp2
						$temp4=$temp3 / 2
						$startingOffset="{0:X}" -f [int]$temp4
						#$startingOffset=("{0:X}" -f [int](($offset1 - 11) - ([System.Math]::Floor((($offset1 - 11) / 3)))) / 2)
						$offsetRow=$offsetRow + [string]$startingOffset
						$lockOffsetRow=$true
					}
					$tempArray+=$file1[$num1].Substring($offset1,1)
				} else {
					if ($tempArray.Length -ge $hexLength) {
						$tempArray|foreach {$bb=$bb+[string]$_}
						for ($i=0; $i -lt $bb.length; $i++) {
							[string]$cc=$bb[$i]
							if ($cc -eq " " -or $cc -eq "0" -or $cc -eq 0) {
								#Do nothing
							} else {
								$printOutput=$true
								break
							}
						}
						if ($printOutput -eq $true) {
							$printOutput=$false
							Write-Host "Starting at Offset: $offsetRow"
							"Starting at Offset: $offsetRow" >> $resultsFile
							Write-Host $bb
							$bb >> $resultsFile
							Write-Host "-------------------------------------------------------------------------------------------------"
							"-------------------------------------------------------------------------------------------------" >> $resultsFile
						}
					}
					$lockOffsetRow=$false
					$offsetRow=$null
					$startingOffset=0
					$tempArray=$null
					$tempArray=@()
					$bb=$null
				}
				$offset1++
				$offset2++
			} else {
				if ($file1[$num1] -eq $null) {
					$counterNull1++
				}
				if ($file2[$num2] -eq $null) {
					$counterNull2++
				}
				$num1++
				$num2++
				$offset1=11
				$offset2=11
			}
		} catch [System.Management.Automation.RuntimeException] {
			if ($tempArray.Length -ge $hexLength) {
				for ($i=0; $i -lt $tempArray.length; $i++) {
					#If any of the indexes are $null, which happen if the end of the base file is doesn't have a full 16Byte row of hex, this will ensure the script does not break.
					try {
						[string]$cc=$bb[$i]
					} catch [System.Management.Automation.RuntimeException] {
						#Do nothing
					}
					if ($cc -eq " " -or $cc -eq "0" -or $cc -eq 0) {
						#Do nothing
					} else {
						$printOutput=$true
						break
					}
				}
			}
			if ($printOutput -eq $true) {	
				$printOutput=$false
				Write-Host "Starting at Offset: $offsetRow"
				"Starting at Offset: $offsetRow" >> $resultsFile
				$tempArray|foreach {$bb=$bb+[string]$_}; Write-Host $bb
				$bb >> $resultsFile
			}
			$bb=$null
			#$printOutput=$false
			$lockOffsetRow=$false
			$offsetRow=$null
			$startingOffset=0
			$tempArray=$null
			$tempArray=@()
			$offset1=11
			$offset2=11
			$counterNull1=0
			$counterNull2=0
			$num1=6
			$num2=6
			break
		}
	}
	$counterNull1=0
	$counterNull2=0
	$num1=6
	$num2=6
}

$listOfFiles | foreach {
	if ($_ -eq "RadiantSherlock.ps1" -or $_ -eq $tempfile1a -or $_ -eq "$tempfile1a.hex.txt" -or $_ -eq "File2.txt" -or $_ -eq $MyInvocation.MyCommand.Name) {
		#Do nothing
	} else {
		Write-Host -ForegroundColor Green "Looking at $_..."
		"Looking at $_..." >> $resultsFile
		Format-Hex "malware\$_" > "File2.txt"
		$file2 = gc "File2.txt"
		Get-TwoComparison
	}
}

if ((Test-Path "completed") -eq $false) {
	New-Item -ItemType Directory "completed"
}
if ((Test-Path "reports") -eq $false) {
	New-Item -ItemType Directory "reports"
}
Move-Item -Force $resultsFile "reports"
Move-Item -Force "$tempfile1a.hex.txt" "completed"
Remove-Item "File2.txt"
Write-Host -ForegroundColor Blue "Results can be found at .\reports\$resultsFile"
Get-Date