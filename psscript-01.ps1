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
    $DeploymentID,

    [string]
    $vmAdminUsername,

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

#Import Common Functions
$path = (Get-Location).Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

# Run Imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon

CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID $vmAdminUsername $trainerUserName $trainerUserPassword

sleep 5

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

sleep 5

# InstallAzCLI

# sleep 5

#Download student files
# Source of truth: CloudLabsAI-Azure/Infra_Monitoring_codefiles (branch: guided-labs), published as a zip to blob storage.
# The zip contains the lab files, including the prebuilt UploadImages.exe that students run in the lab.
$codeFilesZipUrl = "https://experienceazure.blob.core.windows.net/templates/guided-labs/azure-infra-monitoring/dataset/infra-monitor-codefiles.zip"
$file = "C:\infra-monitor-codefiles.zip"
$destination = "C:\AzureInfraMonitoring"

New-Item -ItemType directory -Path $destination -Force | Out-Null
try {
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($codeFilesZipUrl, $file)
    Write-Host "Downloaded student files from $codeFilesZipUrl"

    # Unzip the lab files
    Expand-Archive -Path $file -DestinationPath $destination -Force

    # Remove the mark of the web from the extracted files so that UploadImages.exe
    # does not trigger a SmartScreen "Windows protected your PC" prompt.
    Get-ChildItem -Path $destination -Recurse -File | Unblock-File -ErrorAction SilentlyContinue
    Write-Host "Extracted student files to $destination"
}
catch {
    Write-Host "ERROR: could not download student files from $codeFilesZipUrl - $($_.Exception.Message)"
    Write-Host "ERROR: $destination will be empty. Check the zip has been published to blob storage."
}

# NOTE: Visual Studio and the .NET Core 3.1 SDK are no longer installed.
# The lab does not build or publish any code: the TollBooth functions are deployed to the
# Function App by the ARM template, and UploadImages ships as a self-contained executable.
# The Windows 11 image already includes .NET Framework 4.8.

Stop-Transcript
