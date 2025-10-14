Project 4 - Signing and Submission Instructions

Files included in this folder:
- system_navigator_part2.ps1     (interactive navigator)
- enhanced_system_analysis.ps1  (Project 2 from Exercise 7)
- create_and_sign.ps1           (creates self-signed cert, exports .cer, signs scripts)
- code_signing_cert.cer         (created after running create_and_sign.ps1)

Steps to complete the assignment (ordered):

1) Create and export a self-signed code signing certificate (Admin required)
   - Open PowerShell as Administrator
   - Run:
     .\create_and_sign.ps1
   - This will create a certificate in LocalMachine\My, optionally move the test CA to Trusted Root, export the public cert to code_signing_cert.cer, and sign the two scripts.

2) Verify the scripts are signed
   - Run:
     Get-AuthenticodeSignature .\system_navigator_part2.ps1
     Get-AuthenticodeSignature .\enhanced_system_analysis.ps1
   - Screenshot the output showing SignatureVerificationResult/Status.

3) Change system to only run signed scripts (AllSigned)
   - Open PowerShell as Administrator
   - Run:
     Set-ExecutionPolicy AllSigned -Scope LocalMachine -Force
   - Verify:
     Get-ExecutionPolicy -List
     # or
     Get-ExecutionPolicy
   - Screenshot the Set-ExecutionPolicy command and the verification output showing AllSigned is set.

4) Include the public certificate (.cer) in your upload
   - The exported file is: code_signing_cert.cer in this folder after running create_and_sign.ps1
   - Upload the .cer and both signed .ps1 files to Canvas.

5) Screenshots you must capture and include in the Word document:
   - The create_and_sign.ps1 run output showing certificate creation and export (admin console required)
   - Output of Get-AuthenticodeSignature for both scripts
   - The Set-ExecutionPolicy AllSigned command and Get-ExecutionPolicy showing AllSigned
   - The certificate file (Explorer view) or certmgr output showing the certificate in Trusted Root (optional but helpful)

Notes and cautions:
- Certificate creation requires administrator privileges.
- If you prefer to create the certificate with a different subject name, edit the $certDnsName variable in create_and_sign.ps1.
- AllSigned requires that scripts be signed; once set, unsigned scripts will not run. Keep this in mind when testing.

If you want, I can:
- Run a simulated sequence and paste the expected console output for your Word document captions.
- Modify create_and_sign.ps1 to also place the exported .cer into a ZIP ready for upload.

End of README.