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
$path = pwd
$path=$path.Path
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
New-Item -ItemType directory -Path C:\AzureInfraMonitoring
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://github.com/CloudLabsAI-Azure/Infra_Monitoring_codefiles/archive/refs/heads/code-files.zip","C:\TollBooth_Clean.zip")
#unziping folder
$file = "C:\TollBooth_Clean.zip"
$destination = "C:\AzureInfraMonitoring"
$shell = new-object -com shell.application
$zip = $shell.NameSpace($file)
foreach($item in $zip.items())
{
$shell.Namespace($destination).copyhere($item)
}

#Download and install .net runtime Framework 4.8
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://download.visualstudio.microsoft.com/download/pr/014120d7-d689-4305-befd-3cb711108212/1f81f3962f75eff5d83a60abd3a3ec7b/ndp48-web.exe","C:\Packages\ndp48-web.exe") 
C:\Packages\ndp48-web.exe /silent /install 

sleep 5

#Download and install .NET Core 3.1 Desktop Runtime
choco install dotnetcore-sdk --version=3.1.426
choco install visualstudio2019community --package-parameters "--add Microsoft.VisualStudio.Workload.NetCoreTools"

sleep 5

Stop-Transcript