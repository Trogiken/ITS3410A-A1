<#
create_and_sign.ps1
- Creates a self-signed code signing certificate (requires Admin)
- Exports the public certificate to Module 8\code_signing_cert.cer
- Signs specified scripts in Module 8

Usage (run PowerShell as Administrator):
.\create_and_sign.ps1
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$certDnsName = "its3410-signing-$env:USERNAME"
$certFriendly = "ITS3410 Code Signing ($env:USERNAME)"
$certPath = Join-Path $scriptDir "code_signing_cert.cer"

Write-Host "This script will attempt to create a self-signed code signing certificate in the LocalMachine store."
Write-Host "Run PowerShell as Administrator."

# Create self-signed cert (CodeSigningCert type)
$cert = New-SelfSignedCertificate -DnsName $certDnsName -Type CodeSigningCert -FriendlyName $certFriendly -CertStoreLocation Cert:\LocalMachine\My
if (-not $cert) { Write-Error "Certificate creation failed. Ensure you ran as Administrator."; exit 1 }
Write-Host "Certificate created: $($cert.Thumbprint)"

# Export the public certificate (.cer)
Export-Certificate -Cert $cert -FilePath $certPath -Force | Out-Null
Write-Host "Exported public certificate to: $certPath"

# Make the CA trusted locally (move issuer cert to Root if present)
$ca = Get-ChildItem Cert:\LocalMachine\CA | Where-Object { $_.Subject -like "*${certDnsName}*" } | Select-Object -First 1
if ($ca) {
    try {
        Move-Item -Path $ca.PSPath -Destination Cert:\LocalMachine\Root -ErrorAction Stop
        Write-Host "Moved test CA to Trusted Root store."
    } catch {
        Write-Warning "Could not move CA to Trusted Root: $_"
    }
} else {
    Write-Host "No CA certificate found to move to Trusted Root. Continuing..."
}

# Files to sign
$scriptsToSign = @()
$scriptsToSign += Join-Path -Path $scriptDir -ChildPath 'system_navigator_part2.ps1'
$scriptsToSign += Join-Path -Path $scriptDir -ChildPath 'enhanced_system_analysis.ps1'

foreach ($s in $scriptsToSign) {
    if (Test-Path $s) {
    Write-Host "Signing $s..."
    $sig = Set-AuthenticodeSignature -FilePath $s -Certificate $cert
    Write-Host "Status: $($sig.Status)  Thumbprint: $($sig.SignerCertificate.Thumbprint)"
    } else {
        Write-Warning "File not found: $s"
    }
}

Write-Host "Done. Public certificate is: $certPath"
Write-Host "Upload the public certificate (.cer) and the signed scripts to Canvas as requested."