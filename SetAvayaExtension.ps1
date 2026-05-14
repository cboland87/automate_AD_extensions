Import-Module ActiveDirectory -ErrorAction Stop

$LogFile = "C:\Logs\Avaya_AD_Extension_Update.log"

function Write-Log {
    param ($Message, $Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "{0} [{1}] {2}" -f $ts, $Level, $Message | Out-File -Append $LogFile
}

$userSam   = Read-Host "Enter the user's SamAccountName"
$extension = Read-Host "Enter new 4-digit extension (example: 6262)"

if ($extension -notmatch '^\d{4}$') {
    Write-Log "Invalid extension entered" "ERROR"
    throw "Extension must be 4 digits."
}

$user = Get-ADUser -Filter "SamAccountName -eq '$userSam'" -Properties telephoneNumber -ErrorAction Stop

if ($user.telephoneNumber -notmatch '^\+(\d{11})-(\d{4})$') {
    Write-Log "Unexpected telephone format" "ERROR"
    throw "telephoneNumber format invalid."
}

$baseNumber = $Matches[1]

$newTelephone = "+{0}-{1}" -f $baseNumber, $extension
$formattedBase = "{0}-{1}-{2}" -f `
    $baseNumber.Substring(1,3),
    $baseNumber.Substring(4,3),
    $baseNumber.Substring(7,4)

$attr11 = "{0} Ext. {1}" -f $formattedBase, $extension

Write-Host ""
Write-Host "User: $userSam"
Write-Host "New telephoneNumber  : $newTelephone"
Write-Host "extensionAttribute11: $attr11"
Write-Host ""

Read-Host "Press ENTER to apply or Ctrl+C to cancel"

Set-ADUser -Identity $user.DistinguishedName -Replace @{
    telephoneNumber      = $newTelephone
    extensionAttribute11 = $attr11
}

Write-Log "Updated $userSam to extension $extension"
Write-Host "✅ Update complete."
