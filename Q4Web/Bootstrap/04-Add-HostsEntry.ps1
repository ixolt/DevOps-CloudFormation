function Add-HostsEntry() {

    param(
        [Parameter(Mandatory=$true)]
        [string]
        $IPAddress,

        [Parameter(Mandatory=$true)]
        [string]
        $HostName
    )

    $hostsFile = "$env:windir\System32\drivers\etc\hosts"

    # check if the entry exists
    $lines = Get-Content -Path $hostsFile
    $outLines = New-Object 'Collections.ArrayList'

    foreach($line in $lines) {
        if($line.Contains($ipAddress) -and $line.Contains($hostName)) {
            continue
        } else {
            [void] $outLines.Add($line)
        }
    }

    # Add new entry
    $newLine = "`n{0}`t`t{1}" -f $IPAddress, $HostName

    [void] $outLines.Add($newLine)
    $outLines = $outLines.Trim()

    $outLines | Out-File -Encoding ascii $hostsFile

    $message = "IP Address: {0} and HostName: {1}" -f $IPAddress, $HostName
    Write-Host "$message added to hosts file"
}