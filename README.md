Basic scripts for various uses.
RadiantSherlock.ps1 - A PS1 script that compares files against other selected files at the byte/hex level for similarities matching at the same offset with the same Bytes. 
SlyInquisitor_v2.ps1 - A PS1 script that is designed to identify any missing log entries on a Windows system by parsing thru all the logs. 
Windows_Survey_Script.ps1 - A PS1 script designed to perform a basic survey on a Windows machine for use in further investigations. Requires two dependency files that identifies specific keys in the registry to look thru: regquery_HKLM.txt and regquery_HKU.txt.
Linux_survey.sh - A bash script designed to perform a basic survey on a Linux machine for use in further investigations.
SmithGate.ps1 - A PS1 script, designed to be a persistent backdoor. It gives a user a powershell shell. It communicates in half-duplex: an actor sends commands via one socket, and the output of the commands are sent back to the actor via a separate socket.
