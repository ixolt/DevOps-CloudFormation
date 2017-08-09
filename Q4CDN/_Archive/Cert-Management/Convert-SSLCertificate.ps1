Set-Alias openssl C:\OpenSSL-Win32\bin\openssl.exe

$PfxFile = "star.q4web.newtest.pfx"
$CertName = $PfxFile.Substring(0, $PfxFile.LastIndexOf('.'))

#Write-Host $PfxFile.Substring(0, $PfxFile.LastIndexOf('.'))

# Export the private key file from the pfx file
openssl pkcs12 -in $PfxFile -nocerts -out "$CertName-Key.pem" -passin pass:q4pass1234! -passout pass:q4pass1234!

# Export the certificate file from the pfx file
openssl pkcs12 -in $PfxFile -clcerts -nokeys -out "$CertName.pem" -passin pass:q4pass1234!

# This removes the passphrase from the private key so Apache won't
# prompt you for your passphase when it starts
openssl rsa -in "$CertName-Key.pem" -out "$CertName.key" -passin pass:q4pass1234!