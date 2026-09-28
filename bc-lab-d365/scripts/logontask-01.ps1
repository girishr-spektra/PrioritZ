Param (
    [string]
    $DeploymentID,
    [string]
    $adminUsername = "demouser"
)

Start-Transcript -Path C:\WindowsAzure\Logs\LogonTask.txt -Append

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"

$RepoRawBase = "https://raw.githubusercontent.com/girishr-spektra/PrioritZ/main/bc-lab-d365"
$AssetsDir   = "C:\assets"
$ProjectDir  = "C:\assets\bc-procurement"
$ZipPath     = "C:\assets\bc-procurement-starter.zip"

# Stage 1 (psscript.ps1, userData) already downloaded this alongside the
# trainer-account and VMAgent setup. Reuse it for the same cloudlabs helpers.
if (-not (Test-Path "C:\LabFiles\cloudlabs-windows-functions.ps1")) {
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/cloudlabs-windows-functions.ps1","C:\LabFiles\cloudlabs-windows-functions.ps1")
}
. C:\LabFiles\cloudlabs-windows-functions.ps1


# ---- Lab payload: the starter AL project ----
# Getting Started Task 7 expects the zip at C:\assets\bc-procurement-starter.zip
# and has the participant extract it to C:\assets\bc-procurement. We place the
# zip AND pre-extract it, so Task 7 becomes a verification rather than a step
# that can fail. The zip carries .alpackages symbols so nobody has to run
# "AL: Download Symbols" against a Business Central environment that may not
# exist yet.
Function Get-And-Expand-StarterProject
{
    if (-not (Test-Path $AssetsDir)) {
        New-Item -ItemType Directory -Path $AssetsDir -Force | Out-Null
    }

    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            Invoke-WebRequest -Uri "$RepoRawBase/assets/bc-procurement-starter.zip" -OutFile $ZipPath -UseBasicParsing -ErrorAction Stop
            Expand-Archive -Path $ZipPath -DestinationPath $ProjectDir -Force -ErrorAction Stop

            if (Test-Path (Join-Path $ProjectDir "app.json")) {
                Write-Host "Extracted starter project to $ProjectDir on attempt $attempt"
                return $true
            }
            Write-Host "Attempt $attempt extracted but app.json is missing - retrying"
        }
        catch {
            Write-Host "Attempt $attempt failed to fetch or extract the starter project : $($_.Exception.Message)"
        }
        Start-Sleep -Seconds 15
    }

    Write-Host "ERROR: failed to place the starter project at $ProjectDir after 4 attempts"
    return $false
}
$starterOk = Get-And-Expand-StarterProject


# ---- Stamp the Business Central environment name into launch.json ----
# The shipped launch.json carries BC-ODL-REPLACE_WITH_DEPLOYMENT_ID. If that is
# left in place, Ctrl+F5 fails on the first attempt for every participant. The
# name written here must match the environment the participant creates in the
# Business Central admin centre, which Getting Started tells them to call
# BC-ODL-<DeploymentID>.
if ($starterOk) {
    $launchJson = Join-Path $ProjectDir ".vscode\launch.json"
    if (Test-Path $launchJson) {
        $bcEnvName = "BC-ODL-$DeploymentID"
        (Get-Content -Path $launchJson -Raw) -replace "BC-ODL-REPLACE_WITH_DEPLOYMENT_ID", $bcEnvName | Set-Content -Path $launchJson -NoNewline
        Write-Host "launch.json environmentName set to $bcEnvName"
    }
    else {
        Write-Host "WARNING: $launchJson not found, environmentName not stamped"
    }
}


# ---- Visual Studio Code and the AL Language extension ----
# Getting Started lists both as pre-provisioned. Chocolatey is baked into the
# jumpvm image. The extension installs into the user profile, which is why this
# runs in a real demouser logon session rather than under SYSTEM in stage 1.
Function Resolve-CodeCmd
{
    $candidates = @(
        "C:\Program Files\Microsoft VS Code\bin\code.cmd",
        "C:\Program Files (x86)\Microsoft VS Code\bin\code.cmd",
        "C:\Users\$adminUsername\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

$codeCmd = Resolve-CodeCmd
if (-not $codeCmd) {
    Write-Host "Visual Studio Code not found on the image, installing via Chocolatey"
    choco install vscode -y --no-progress
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $codeCmd = Resolve-CodeCmd
}

if ($codeCmd) {
    Write-Host "Using VS Code at $codeCmd"
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        & $codeCmd --install-extension ms-dynamics-smb.al --force 2>&1 | Write-Host
        $installed = & $codeCmd --list-extensions 2>&1
        if ($installed -match "ms-dynamics-smb.al") {
            Write-Host "AL Language extension installed on attempt $attempt"
            break
        }
        Write-Host "Attempt $attempt did not register the AL extension - retrying"
        Start-Sleep -Seconds 15
    }
}
else {
    Write-Host "ERROR: Visual Studio Code could not be located or installed"
}


# ---- Convenience: desktop shortcut straight to the project folder ----
try {
    $desktop = "C:\Users\Public\Desktop"
    if (-not (Test-Path $desktop)) { New-Item -ItemType Directory -Path $desktop -Force | Out-Null }
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut("$desktop\BC Procurement Project.lnk")
    $lnk.TargetPath = $ProjectDir
    $lnk.Description = "Starter AL project for the Business Central lab"
    $lnk.Save()
    Write-Host "Created desktop shortcut to $ProjectDir"
}
catch {
    Write-Host "Could not create the desktop shortcut : $($_.Exception.Message)"
}


# ---- Summary for the deployment log ----
Write-Host "---- BC lab setup summary ----"
Write-Host "Starter project present : $(Test-Path (Join-Path $ProjectDir 'app.json'))"
Write-Host "Symbols present         : $(Test-Path (Join-Path $ProjectDir '.alpackages'))"
Write-Host "Zip present             : $(Test-Path $ZipPath)"
Write-Host "BC environment expected : BC-ODL-$DeploymentID"

# One-shot task, remove it so it does not fire again on the next logon.
Unregister-ScheduledTask -TaskName "Setup" -Confirm:$false

Stop-Transcript
