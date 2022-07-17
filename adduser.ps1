# Loading .NET assembly System.Windows.Forms with a class inside called OpenFileDialog
# to get GUI chose file dialog
Add-Type -AssemblyName System.Windows.Forms

Write-Host -BackgroundColor Black -ForegroundColor Green `
"Adding new client to your Wireguard Server:
- First select ssh key file from GUI dialog
- Then enter other values in command line
Press Enter to continue or CTRL+C to quit"
$null = Read-Host 

# Set up and open GUI file select dialog
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.InitialDirectory = $env:USERPROFILE
$OpenFileDialog.Title = "Select server ssh key file"
$OpenFileDialog.filter = "All files (*.*)| *.*"
# Reload dialog window to put it on top
$result = $OpenFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))

if ($result -eq [Windows.Forms.DialogResult]::OK){
    $SSHKey = $OpenFileDialog.FileName
}
else {
    Write-Host -BackgroundColor Black -ForegroundColor Red "You need to select ssh key file"
    exit
}

$SSHKey = $OpenFileDialog.FileName
Write-Host -ForegroundColor DarkYellow -BackgroundColor Black "Enter Wireguard parameters"
#$ServerIP = Read-Host -Prompt 'IP address'

Write-Host -ForegroundColor Gray -BackgroundColor Black "# IP Address of Wiregiard Server"
Write-Host -ForegroundColor Blue -BackgroundColor Black "- Server IP Address: " -NoNewline
$ServerIP = Read-Host

Write-Host -ForegroundColor Gray -BackgroundColor Black "# Public key from wireguard client"
Write-Host -ForegroundColor Blue -BackgroundColor Black "- Client Public Key: " -NoNewline
$ClientPubKey = Read-Host

Write-Host -ForegroundColor Gray -BackgroundColor Black "# IP address from wireguard client config
# Allowed range from 10.10.10.11 to 10.10.10.254
# Note that no two peers can have the same Allowed IP setting"
Write-Host -ForegroundColor DarkMagenta -BackgroundColor Black "Already taken IPs:"
# Run 'sudo wg' on remote server and grep ip addresses from output
# -o show only matched -P use Perl regexp
# ?<= search but exclude from output
$Command = "sudo wg | grep -oP '(?<=allowed ips: )\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}'"
# Out-String convert output to string
$IPTaken = ssh -i $SSHKey ubuntu@${ServerIP} $Command | Out-String

if ($IPTaken -eq ''){
    Write-Host -ForegroundColor Green -BackgroundColor Black "No IP taken"
}
else {
    Write-Host -BackgroundColor Black -ForegroundColor DarkMagenta ($IPTaken -replace " +", "`n")
}
Write-Host -ForegroundColor Blue -BackgroundColor Black "- Allowed Client IP: " -NoNewline
$AllowedIPs = Read-Host

# Run command on remote server to add peer
$Command = "sudo wg set wg0 peer $ClientPubKey allowed-ips $AllowedIPs"
ssh -i $SSHKey ubuntu@${ServerIP} $Command

# Powershell does not cath this
# try {
#     ssh -i $SSHKey ubuntu@${ServerIP} $Command
# }
# catch {
#     Write-Host "An error occurred: "
#     Write-Host $_.Exception
# }

