Param (
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUserName,
    [string]
    $AzurePassword,
    [string]
    $AzureTenantID,
    [string]
    $AzureSubscriptionID,
    [string]
    $ODLID,
    [string]
    $DeploymentID,
    [string]
    $adminUsername,
    [string]
    $adminPassword,
    [string]
    $trainerUserName,
    [string]
    $trainerUserPassword
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

$RepoRawBase = "https://raw.githubusercontent.com/girishr-spektra/PrioritZ/main/bc-lab-d365"

# NOTE: Running on the Spektra cloudlabs-windows-jumpvm image.
# Az CLI, Az PowerShell, Edge and Chocolatey are already baked into the image.
# The trainer local account and the CloudLabs VM Agent service are NOT baked in,
# so cloudlabs-windows-functions.ps1 is pulled down (this script is delivered via
# raw userData, not a zip, so there is no local cloudlabs-common\ folder to
# dot-source) and its real setup functions are used instead of hand-rolled ones.
$WebClient = New-Object System.Net.WebClient
New-Item -ItemType directory -Path C:\LabFiles -Force | Out-Null
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/cloudlabs-windows-functions.ps1","C:\LabFiles\cloudlabs-windows-functions.ps1")
. C:\LabFiles\cloudlabs-windows-functions.ps1
InstallModernVmValidator

Function CreateCredFile($AzureUserName, $AzurePassword, $AzureTenantID, $AzureSubscriptionID, $DeploymentID)
{
    New-Item -ItemType directory -Path C:\LabFiles -force

    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/AzureCreds.txt","C:\LabFiles\AzureCreds.txt")
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/AzureCreds.ps1","C:\LabFiles\AzureCreds.ps1")

    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$AzureUserName"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$AzurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$AzureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$AzureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$DeploymentID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"

    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$AzureUserName"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$AzurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$AzureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$AzureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$DeploymentID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"

    Copy-Item "C:\LabFiles\AzureCreds.txt" -Destination "C:\Users\Public\Desktop"
}
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID

Enable-CloudLabsEmbeddedShadow $adminUsername $trainerUserName $trainerUserPassword

# ---- Hand off the network-heavy, GitHub-dependent steps to a logon task ----
# Downloading from raw.githubusercontent.com and installing a VS Code extension
# are both unreliable under the headless userData/SYSTEM boot context. The VS Code
# extension in particular installs into the user profile, so it has to run in a
# real demouser session. Same pattern as the hiad/knowledge-navigator-agent lab.

$logonTaskPath = "C:\LabFiles\logontask-01.ps1"
for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
        Invoke-WebRequest -Uri "$RepoRawBase/scripts/logontask-01.ps1" -OutFile $logonTaskPath -UseBasicParsing -ErrorAction Stop
        Write-Host "Downloaded logontask-01.ps1 on attempt $attempt"
        break
    }
    catch {
        Write-Host "Attempt $attempt failed to download logontask-01.ps1 : $($_.Exception.Message)"
        Start-Sleep -Seconds 10
    }
}

$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\$adminUsername" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value $adminPassword -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord

# DeploymentID is passed through so the logon task can stamp the Business Central
# environment name into .vscode/launch.json.
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$User = "$($env:ComputerName)\$adminUsername"
$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-ExecutionPolicy Unrestricted -WindowStyle Hidden -File C:\LabFiles\logontask-01.ps1 -DeploymentID $DeploymentID -adminUsername $adminUsername"
Register-ScheduledTask -TaskName "Setup" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force

Stop-Transcript

# Disable the image's bootstrap task so it does not run again on the reboot below.
# Do NOT Stop-ScheduledTask here: this script IS that task's own running process,
# so stopping it would kill this process before Restart-Computer ever runs.
Disable-ScheduledTask -TaskName "runuserdata"
Restart-Computer -Force
