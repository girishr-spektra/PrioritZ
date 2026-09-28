## Getting Started with Your Lab

Welcome to the **Extending Business Central with Power Platform, AL and Copilot Studio Hack in a Day**! Your Business Central environment, Power Platform environments, Visual Studio Code and the starter AL project are already provisioned. In this page you will sign in to each surface, record the environment details the challenges depend on, confirm your entitlements, and download the starter project.

Work through every step below before starting Challenge 01. Skipping the verification tasks is the most common cause of losing time later, because a missing entitlement only shows up three challenges in.

### Accessing Your Challenge Environment

Once you're ready, your virtual machine and challenge guide will be available within your web browser.

### Exploring Your Challenge Resources

To get a better understanding of your challenge resources and credentials, navigate to the **Environment** tab.

![](./media/gs-environment-tab.png)

### Utilizing the Split Window Feature

For convenience, you can open the challenge guide in a separate window by selecting the **Split Window** button from the top right corner.

![](./media/gs-split-window.png)

### Managing Your Virtual Machine

Feel free to start, stop, or restart your virtual machine as needed from the **Resources** tab. Your experience is in your hands!

![](./media/gs-resources-tab.png)

> **Note:** If the VM is not in use, please **deallocate** it to avoid unnecessary resource consumption.

## Your Lab Credentials

| Field | Value |
|---|---|
| **Username** | <inject key="AzureAdUserEmail"></inject> |
| **Password** | <inject key="AzureAdUserPassword"></inject> |
| **Deployment ID** | <inject key="DeploymentID" enableCopy="false"></inject> |

> **Important:** You are working in a shared tenant alongside other participants. Your **Deployment ID** is what keeps your work separate from theirs. Every time a challenge asks you to name something with `<inject key="DeploymentID" enableCopy="false"></inject>` at the end, use your own ID exactly as shown above. If you skip it, you will collide with another participant and both of you will lose work.

## Your Pre-Provisioned Resources

| Resource | Where to find its name | Used In |
|---|---|---|
| Business Central environment | **Environment** tab of your lab portal | Challenges 01, 02, 03, 05 |
| Business Central company | **Environment** tab of your lab portal | All challenges |
| AL object ID range | **Environment** tab of your lab portal | Challenge 01 |
| Power Platform dev environment | `ODL_User <inject key="DeploymentID" enableCopy="false"></inject>'s Environment` | Challenges 02, 03, 04, 05 |
| Power Platform UAT environment | `UAT-<inject key="DeploymentID" enableCopy="false"></inject>` | Challenge 05 |
| Visual Studio Code | Installed on the JumpVM with the AL Language extension | Challenge 01 |

Your account already holds a Business Central licence and a Copilot Studio user licence. You do not need to request either.

> **Important:** Read your Business Central environment name, company name and AL object ID
> range off the **Environment** tab and write them down now. Do not assume they match the
> examples in the challenge guides. Your object ID range in particular is assigned to you
> alone, because object IDs are unique across the whole Business Central environment and two
> participants using the same range will collide.

## Task 1: Sign In to the JumpVM and Business Central

1. In the JumpVM, click on the **Microsoft Edge** browser shortcut on the desktop.

   ![](./media/gs-edge-shortcut.png)

1. Navigate to Business Central:

   ```
   https://businesscentral.dynamics.com
   ```

1. On the **Sign in** page, enter the following email address and then click **Next**.

   - Email: **<inject key="AzureAdUserEmail"></inject>**

     ![](./media/gs-signin-email.png)

1. On the **Enter password** screen, enter the following password and then click **Sign in**.

   - Password: **<inject key="AzureAdUserPassword"></inject>**

     ![](./media/gs-signin-tap.png)

1. If you see the pop-up **Stay signed in?**, click **No**.

   ![](./media/gs-stay-signed-in.png)

1. Business Central opens. If you see **Getting ready...** or **Working on it...**, wait.
   The first sign-in can take several minutes while your environment is prepared.

1. Confirm the company shown in the top-left corner matches the company name on your
   **Environment** tab. If it does not, select the **Settings** gear icon, then
   **My Settings**, and change the **Company** field.

1. Confirm your environment name and type. Select **Help** (**?**), then **Help & Support**,
   and scroll to **Report a problem**. It prints a line like
   `Microsoft Entra tenant ID: ..., Environment: <name> (<type>)`. Write down both the name
   and the type, because Challenge 01 deploys differently depending on the type.

   > **Note:** Also note the **Version** line just below it, for example
   > `US Business Central 28.3 (Platform 28.0.53445.0 + Application 28.3.52162.53725)`.
   > Challenge 01 needs the major version, `28`, to set up the AL project correctly.

   > **Important:** You may be sharing this Business Central environment and company with
   > other participants. If so, you will see their purchase orders alongside yours, and the
   > AL object ID range on your **Environment** tab is what keeps your Challenge 01
   > extension from colliding with theirs. Use your assigned range and nothing else.

1. Use the **Tell Me** search (the magnifying glass, or press **Alt+Q**), type `Purchase Orders`, and open the **Purchase Orders** list. Confirm that purchase orders and vendors are present. This is the data every later challenge reads.

## Task 2: Confirm You Can Deploy an Extension

Challenge 01 deploys an AL extension into Business Central. How you deploy depends on the
environment type you noted in Task 1.

- **Sandbox** - you can publish straight from Visual Studio Code with **Ctrl+F5**.
- **Production** - you cannot. Visual Studio Code publishing produces a DEV extension, and
  DEV extensions only exist in sandboxes. You will build the package and upload it instead.
  Challenge 01 walks you through this.

1. In Business Central, open **Tell Me** and search for `Extension Management`, then open it.

1. Confirm the page loads and lists the installed extensions.

1. Select **...** (More options), then **Manage**, and confirm **Upload Extension...** is
   present and not greyed out. This is the route Challenge 01 uses on a production
   environment.

   > **Note:** You will not upload anything yet. You are confirming the page opens and the
   > action is available, because Challenge 01 depends on it and finding out later costs you
   > an hour.

1. Note which extensions are already installed, and from which publishers. If a
   non-Microsoft extension is present, it already owns some object IDs in this environment,
   which is why your assigned object ID range matters.

   > **Important:** Challenge 01 creates a new table. Business Central will not let you add
   > records to a table from a per-tenant extension unless the extension's permission set has
   > been assigned to your user, and assigning permission sets is not something your lab
   > account can do. If **+ New** is greyed out on the **Project Budgets** page in Challenge
   > 01, contact CloudLabs support and ask for the **BC Procurement** permission set to be
   > assigned to your user.

## Task 3: Verify Power Platform Access

1. Open a new browser tab and navigate to Power Apps:

   ```
   https://make.powerapps.com
   ```

1. In the environment picker in the top-right corner, select `ODL_User <inject key="DeploymentID" enableCopy="false"></inject>'s Environment`.

   > **Important:** Every component you build in Challenges 02 to 04 must live in this environment. If you build in the **Default** environment, Challenge 05 will not be able to package it and you will have to rebuild.

1. Confirm you can also see `UAT-<inject key="DeploymentID" enableCopy="false"></inject>` in the same picker. You will not use it until Challenge 05, but it must exist now.

1. Open a new tab and navigate to Power Automate:

   ```
   https://make.powerautomate.com
   ```

1. Confirm the same environment is selected in the top-right corner.

## Task 4: Verify the Business Central Connector

The Dynamics 365 Business Central connector is a **premium** connector. This task confirms your account is licensed for it before you build anything that depends on it.

1. In Power Automate, select **+ Create (1)** from the left navigation pane, then choose **Instant cloud flow (2)**.

1. Name the flow `Connector Test <inject key="DeploymentID" enableCopy="false"></inject>`, select **Manually trigger a flow**, and select **Create**.

1. Select **+ New step**, and search for `Business Central`.

1. Confirm that **Dynamics 365 Business Central** appears in the results with a **Premium** tag.

1. Select any action from it, for example **Get record**. When prompted, sign in with your lab credentials to create the connection.

1. Confirm the connection is created and the action loads its **Environment** and **Company** dropdowns without an error.

   > **Note:** If you see a licensing error rather than the dropdowns, stop here and contact CloudLabs support. Every challenge from 02 onward depends on this connector.

1. Discard the flow without saving. Its only purpose was this check.

## Task 5: Verify Copilot Studio Access

1. Open a new browser tab and navigate to Copilot Studio:

   ```
   https://copilotstudio.microsoft.com
   ```

1. Sign in with your lab credentials if prompted.

1. In the environment picker in the top-right corner, select `ODL_User <inject key="DeploymentID" enableCopy="false"></inject>'s Environment`.

1. Confirm you can see the **Create** option in the left navigation pane and that selecting it offers **New agent**. Do not create one yet.

   > **Important:** You must be able to **publish** an agent in Challenge 04, not merely create one. Your account holds a Copilot Studio user licence for this reason. If the **Create** option is missing or greyed out, contact CloudLabs support now.

## Task 6: Verify Microsoft Teams and Approvals

Challenge 03 routes purchase orders through Teams approval cards. Without a Teams licence
the flow starts, sends the approval, and then waits indefinitely for a response that can
never arrive.

1. Open a new browser tab and navigate to Microsoft Teams:

   ```
   https://teams.microsoft.com
   ```

1. Sign in with your lab credentials if prompted.

1. In the left rail, select the **...** (More apps) button, search for `Approvals`, and open
   it.

1. Confirm the **Approvals** app loads and shows **Received** and **Sent** tabs. It will be
   empty, which is correct - you have not raised one yet.

   > **Important:** If Teams does not load, or the Approvals app is unavailable, stop and
   > contact CloudLabs support. Your account needs a licence that includes Microsoft Teams,
   > such as Microsoft 365 Business Basic. Challenge 03 cannot be completed without it, and
   > the failure mode is silent: the flow will simply sit at **Running** until it times out.

## Task 7: Download the Starter AL Project

1. On the JumpVM, open **File Explorer** and browse to:

   ```
   C:\assets
   ```

1. Confirm the folder contains `bc-procurement-starter.zip`.

1. Right-click the file, select **Extract All**, and extract it to:

   ```
   C:\assets\bc-procurement
   ```

1. Confirm the extracted folder contains:

   | File | Purpose |
   |---|---|
   | `app.json` | Extension metadata, with your object ID range already set |
   | `.vscode/launch.json` | Connection settings for your Business Central environment |
   | `src/` | Empty folder where you will write your AL files |

1. Open `app.json` and confirm three things against what you noted in Task 1:

   - `idRanges` matches the object ID range on your **Environment** tab
   - `platform` and `application` are both set to your Business Central major version, for
     example `28.0.0.0`
   - `version` is `1.0.0.0`

   > **Important:** If `platform` or `application` names an older major version than your
   > environment, the build in Challenge 01 fails with `error AL1022: A package with
   > publisher 'Microsoft', name 'Application' ... could not be found`. Correct it now and
   > save the file.

   > **Note:** If `C:\assets` is missing or empty, contact CloudLabs support. Do not
   > hand-build the project from scratch, because `app.json` carries the object ID range
   > assigned to you and guessing it will cause a collision in Challenge 01.

## Task 8: Confirm Visual Studio Code Can Reach Business Central

This is the single most important verification on this page. If symbols do not download, Challenge 01 cannot start.

1. On the JumpVM, open **Visual Studio Code**.

1. Select **File**, then **Open Folder**, and choose:

   ```
   C:\assets\bc-procurement
   ```

1. Open `.vscode/launch.json` and confirm `environmentName` matches the environment name you
   noted in Task 1, and that `environmentType` matches its type, `Sandbox` or `Production`.
   If either is wrong, correct it now and save the file.

   > **Tip:** Business Central can write this file for you. In Business Central, go to
   > **Help > Help & Support**, and under **Troubleshooting** select
   > **Generate launch configurations for this environment**.

1. Press **Ctrl+Shift+P** to open the command palette, type `AL: Download Symbols`, and press **Enter**.

1. When a browser window opens asking you to sign in, use your lab credentials.

1. Watch the **Output** panel at the bottom of Visual Studio Code. A successful run ends with a message confirming the symbols were downloaded.

   > **Important:** If this fails, do not continue to Challenge 01. Check in order: the
   > `environmentName` in `launch.json` matches your environment exactly, the `tenant` value
   > is correct, and you signed in with your lab account rather than a personal one. If it
   > still fails, contact CloudLabs support.

   > **Note:** Symbol download talks to the Business Central development endpoint, which is
   > open by default on sandboxes. If your environment is **Production** and this step fails,
   > that is expected rather than a fault in your setup. Say so when you contact support, and
   > confirm how symbols should be supplied for your environment before starting Challenge 01.

## Reference: Key URLs

| Resource | URL |
|---|---|
| Business Central | https://businesscentral.dynamics.com |
| Business Central admin centre | https://businesscentral.dynamics.com/admin |
| Power Apps | https://make.powerapps.com |
| Power Automate | https://make.powerautomate.com |
| Copilot Studio | https://copilotstudio.microsoft.com |
| Microsoft Teams | https://teams.microsoft.com |

## You Are Ready

Business Central is reachable, you know your environment name, type, version, company and
object ID range, you have confirmed you can deploy an extension, the premium Business
Central connector is licensed to your account, and you can create an agent in Copilot
Studio. Everything the five challenges depend on has been confirmed.

## Support Contact

The CloudLabs support team is available 24/7, 365 days a year, via email and live chat to ensure seamless assistance at any time.

Learner Support Contacts:

- Email Support: cloudlabs-support@spektrasystems.com
- Live Chat Support: https://cloudlabs.ai/labs-support

Click **Next** at the bottom of the page to proceed to Challenge 01.

![](./media/next.png)
