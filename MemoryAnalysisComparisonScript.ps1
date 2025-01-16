#This script parses thru a list of dump files using Volatility 3, and will display values that only appear once throughout all of the files. By default, it was made for Process Lists, but the parameters below allow a user to easily modify it for other fields.
#Script must be ran in directory User expects to work out of. User must create a .\dumps\ directory and place all memory dumps inside this directory.
#User must manually enter path of volatility at Line 29.
#-Command: The volatility3 argument to feed to volatility.
#-Field: The column name the user wants to compare/parse thru.
param (
	[Parameter()]
	[string]$Command="windows.pslist",
	
	[Parameter()]
	[string]$Field="ImageFileName"	
)

Date
if (!(Test-Path .\dumps\)) {
	Write-Host -ForegroundColor RED "Must create the .\dumps\ directory and place all memory dumps inside it."
	exit
}
Remove-Item -Recurse -Force .\analysis\ 2>$null 1>$null
if (!(Test-Path .\analysis\)) {
	mkdir .\analysis\
}

$count1=1
$whiteList=@()
$uniqueBinary=$null
$array1=(Get-ChildItem .\dumps\).Name
$array1|foreach {
	python C:\Users\smith\volatility3\vol.py -q -f .\dumps\$_ $Command >> .\analysis\raw$count1
	Get-Content .\analysis\raw$count1 | Select-Object -Skip 2 >> .\analysis\SecondRaw$count1
	Import-Csv .\analysis\SecondRaw$count1 -Delimiter "`t"| Export-Csv .\analysis\output$count1 -NoTypeInformation
	$count1++
}
$count1=0
$array2=(Get-ChildItem .\analysis\output*).Name

#Main loop to parse thru the dumps.
foreach($filename in $array2) {
	$array3=(Import-Csv .\analysis\$filename).$Field
	
	#Loop that parses thru each value in the identified list and compares it to each dump file to see if it exists.
	foreach($binaryName in $array3) {
		foreach($newFilename in $array2) {
			if ($newFilename -eq $filename) {	#Ensure the selected file does not compare itself with itself
				continue
			} elseif($whiteList -contains $binaryName) {	#Checks the list of previously seen values and moves on if the current value was already seen
				continue
			} else {	#Checks to see if the current value is seen within a dump file: if it is seen, adds the value to the $whiteList array
				$array4=(Import-Csv .\analysis\$newFilename).$Field
				if($array4 -contains $binaryName) {
					$whiteList+=$binaryName
					break
				} else {
					$uniqueBinary=$binaryName
				}
			}
		}
		if ($uniqueBinary -ne $null) {	#If the value was never seen in any other dumps, outputs to screen the name of the value and which file/dump it was seen in
			Write-Host "$uniqueBinary only appears once in Dump File: $($array1[$count1])"
			$whiteList+=$uniqueBinary
		}
		$uniqueBinary=$null
	}
	$count1++
}
Date