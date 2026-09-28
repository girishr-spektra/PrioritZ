# BC Lab (D365 Business Central Extension) - deployment

ARM template and VM bootstrap for the Hack in a Day lab
[d365-business-central-extension](https://github.com/girishr-spektra/giri-hack/tree/main/d365-business-central-extension).

Staged here for testing. Once a deployment comes up clean, move it to DevOps and
re-point the URLs at `experienceazure.blob.core.windows.net`.

## Layout

```
bc-lab-d365/
├── deploy/
│   ├── deploy.json                    ARM template
│   └── deploy.parameters.json         CloudLabs parameter placeholders
├── scripts/
│   ├── psscript.ps1                   stage 1, runs headless via userData
│   └── logontask-01.ps1               stage 2, runs once in a demouser session
└── assets/
    └── bc-procurement-starter.zip     starter AL project, 6.5 MB
```

## CloudLabs template registration

| Field | Value |
|---|---|
| Cloud | Microsoft Azure |
| Resource type | Resource Group |
| Name | RG - 01 |
| Resource group | `challenge-rg` |
| Template URL | `https://raw.githubusercontent.com/girishr-spektra/PrioritZ/main/bc-lab-d365/deploy/deploy.json` |
| Parameters URL | `https://raw.githubusercontent.com/girishr-spektra/PrioritZ/main/bc-lab-d365/deploy/deploy.parameters.json` |

## What deploys

One `labvm-<DeploymentID>` on the Spektra `cloudlabs-windows-jumpvm` image
(`win2019`, `Standard_D2s_v3`), with vNet, NSG, public IP and NIC. Same shape as
the `hiad/knowledge-navigator-agent` template this was derived from.

### Stage 1, `psscript.ps1`

Delivered as raw `userData` and run by the image's `runuserdata` task under SYSTEM.

1. Pulls `cloudlabs-windows-functions.ps1` and runs `InstallModernVmValidator`
2. Writes `AzureCreds.txt` / `AzureCreds.ps1` and copies the txt to the Public Desktop
3. `Enable-CloudLabsEmbeddedShadow` for the trainer account
4. Downloads `logontask-01.ps1`, registers it as a one-shot `Setup` task, enables autologon
5. Disables `runuserdata` and reboots

No Python work. The reference lab downgrades Python for its own reasons; this lab
does not use it.

### Stage 2, `logontask-01.ps1`

Runs once at first logon, as `demouser`, elevated. This is where the network and
user-profile work happens, because both are unreliable under SYSTEM at boot.

1. Downloads `bc-procurement-starter.zip` to `C:\assets\`
2. Extracts it to `C:\assets\bc-procurement` and verifies `app.json` landed
3. Rewrites `BC-ODL-REPLACE_WITH_DEPLOYMENT_ID` in `.vscode/launch.json` to
   `BC-ODL-<DeploymentID>`
4. Installs VS Code if the image does not carry it, then installs the
   `ms-dynamics-smb.al` extension and verifies it registered
5. Drops a desktop shortcut to the project folder
6. Unregisters itself

Every network step retries. The transcript is at `C:\WindowsAzure\Logs\LogonTask.txt`.

## What is in the starter zip

The **scaffold**, not the finished extension. Writing the AL code is Challenge 01.

```
app.json                    manifest, id range 50100-50149, platform/application 28.0.0.0
.vscode/launch.json         Sandbox publish profile, environmentName stamped at deploy time
src/                        empty, participants write their AL files here
.alpackages/                5 symbol files:
                              Microsoft_Application_28.3.52162.52273.app
                              Microsoft_Base Application_28.3.52162.52273.app
                              Microsoft_Business Foundation_28.3.52162.52273.app
                              Microsoft_System Application_28.3.52162.52273.app
                              System.app                    (platform, 28.0.54265)
```

The symbols are bundled deliberately. Without them every participant runs
`AL: Download Symbols`, which needs a live authenticated Business Central
environment and is a reliable twenty minute stall five minutes into the lab.
They still work if the environment is a later 28.x, because `app.json` pins
`28.0.0.0`.

**All five files are required.** `System.app` is the platform package and is easy
to miss, because it is the only one without a `Microsoft_` prefix and it does not
come from the same place as the rest. Omit it and the first build fails with:

```
error AL1022: A package with publisher 'Microsoft', name 'System', and a version
compatible with '28.0.0.0' could not be found in the package cache folders
```

It comes from `Microsoft.Platform.symbols` on Microsoft's public symbol feed:

```
https://dynamicssmb2.pkgs.visualstudio.com/DynamicsBCPublicFeeds/_packaging/MSSymbols/nuget/v3/index.json
```

Verified: the bundled set compiles a `tableextension` against `Purchase Header`
with AL Language **18.0**, which is the version the VM installs today.

## The pre-built extension

`assets/Contoso_BC Procurement Extension_1.0.0.0.app` supports the alternate
Challenge 01, [easy-challenge1.md](https://github.com/girishr-spektra/giri-hack/blob/main/d365-business-central-extension/easy-challenge1.md),
where the participant uploads a finished extension instead of writing the AL.
Stage 2 drops it at `C:ssets\`.

It is compiled from exactly the source printed in the standard `challenge-1.md`,
so the two variants produce an identical extension. Verified with AL Language
18.0. `SymbolReference.json` in the package declares:

```
Tables            50100  Project Budget
Pages             50100  Project Budget List
                  50101  Purchase Order API
                  50102  Project Budget API
Codeunits         50100  Project Budget Mgmt
TableExtensions   50100  Purchase Header Ext
PageExtensions    50100  Purchase Order Ext
PermissionSets    50100  BC Procurement
```

That last line matters. **Upload Extension validates permission sets and
`Ctrl+F5` does not.** An otherwise-correct package without it is rejected with
`PTE0004: Table 50100 'Project Budget' is missing a matching permission set`.

The codeunit includes the Purchase Line and Purchase Header event subscribers, so
committed spend stays current without anyone pressing **Recalculate Spend**.
Without those, every figure the app and the agent report downstream is frozen at
whatever it was when that button was last pressed.

**Running the standard variant instead?** Delete the `Get-PrebuiltExtension`
block from `scripts/logontask-01.ps1`, or participants will find the finished
extension sitting next to the project they are meant to be building.

## Not in the template

Automated separately, by arrangement:

- Tenant, single user, Global Administrator plus D365 Business Central
  Administrator and Power Platform Administrator
- Licences: BC Premium, Power Apps Premium, Power Automate Premium, Copilot
  Studio, Microsoft 365 Business Basic

Business Basic is not optional. Challenge 03 delivers approvals through Teams,
and without a mailbox and Teams entitlement the flow starts, sends the approval
and waits until it times out with nothing in the run history to explain it.

Created by the participant during Getting Started:

| Environment | Name | Type |
|---|---|---|
| Business Central | `BC-ODL-<DeploymentID>` | Sandbox, United States, 28.0+ |
| Power Platform dev | `Contoso-Dev-<DeploymentID>` | Sandbox with Dataverse |
| Power Platform UAT | `Contoso-UAT-<DeploymentID>` | Sandbox with Dataverse |

The Business Central name must match exactly, because stage 2 stamps it into
`launch.json` before the participant creates it.

## Template outputs

Beyond the usual VM outputs, these populate the lab portal's Environment tab,
which Getting Started tells participants to read:

- Business Central environment name
- Business Central company (`CRONUS USA, Inc.`)
- AL object ID range (`50100 - 50149`)
- Power Platform dev environment
- Power Platform UAT environment

## Verifying a deployment

On the VM after first logon:

```powershell
Test-Path C:\assets\bc-procurement\app.json          # True
Test-Path C:\assets\bc-procurement\.alpackages       # True
Get-Content C:\assets\bc-procurement\.vscode\launch.json | Select-String environmentName
code --list-extensions | Select-String ms-dynamics-smb.al
Get-Content C:\WindowsAzure\Logs\LogonTask.txt -Tail 40
```

`environmentName` must read `BC-ODL-<DeploymentID>` and not the
`REPLACE_WITH_DEPLOYMENT_ID` placeholder.

## Moving to DevOps

Change `repoRawBase` in `deploy/deploy.json` and `$RepoRawBase` in both scripts
to the blob path, upload `deploy/`, `scripts/` and `assets/` to it, and update
the two template URLs registered in CloudLabs.
