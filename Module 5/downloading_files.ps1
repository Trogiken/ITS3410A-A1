Set-StrictMode -Version Latest

function Invoke-WebRequest-Example {
	param(
		[Parameter(Mandatory=$true)] [string] $Uri,
		[Parameter(Mandatory=$true)] [string] $OutFile
	)

	Write-Host "Invoke-WebRequest: downloading $Uri -> $OutFile"
	Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
}

function Start-BitsTransfer-Example {
	param(
		[Parameter(Mandatory=$true)] [string] $Source,
		[Parameter(Mandatory=$true)] [string] $Destination
	)

	Write-Host "Start-BitsTransfer: downloading $Source -> $Destination"
	Start-BitsTransfer -Source $Source -Destination $Destination -ErrorAction Stop
}

function WebClient-Example {
	param(
		[Parameter(Mandatory=$true)] [string] $Uri,
		[Parameter(Mandatory=$true)] [string] $OutFile
	)

	Write-Host "WebClient: downloading $Uri -> $OutFile"
	$wc = New-Object System.Net.WebClient
	try {
		$wc.DownloadFile($Uri, $OutFile)
	}
	finally {
		$wc.Dispose()
	}
}

function HttpClient-Example {
	param(
		[Parameter(Mandatory=$true)] [string] $Uri,
		[Parameter(Mandatory=$true)] [string] $OutFile
	)

	Write-Host "HttpClient: downloading $Uri -> $OutFile"
	Add-Type -AssemblyName System.Net.Http
	$client = [System.Net.Http.HttpClient]::new()
	try {
		$response = $client.GetAsync($Uri).Result
		$response.EnsureSuccessStatusCode()
		$bytes = $response.Content.ReadAsByteArrayAsync().Result
		[System.IO.File]::WriteAllBytes($OutFile, $bytes)
	}
	finally {
		$client.Dispose()
	}
}

Write-Host "downloading_files.ps1 loaded. Call one of the functions to download a file."
