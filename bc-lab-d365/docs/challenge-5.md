# Challenge 05: Package and Deploy

## Introduction

Everything works. The extension tracks project spend inside Business Central, the app gives approvers budget context, the flow routes by amount and keeps an audit trail, and the agent answers questions from live data. All of it exists in exactly one place: your development environment.

That is not a solution, it is a demonstration. A solution is something that can be moved. Contoso has a UAT environment and a production tenant, and neither will accept "rebuild it by hand and hope you remember every setting". The difference between those two things is packaging, and packaging is where most Power Platform projects discover what they got wrong.

In this challenge you will package the Power Platform components into a managed solution, handle the fact that the AL extension cannot go in that solution at all, deploy to UAT, and validate the result end to end. The final task gives you no steps, because by then you will have done it once already.

## Challenge Objectives

- Package the app, flows, agent and table into a managed solution
- Understand why the AL extension deploys on a separate track and document the sequence
- Export a managed solution and import it into a second environment
- Map connection references during import
- Validate the deployed solution end to end without step-by-step guidance

## Duration

40 minutes

## Your Assignment

> Contoso's IT change board will not approve a production deployment without a runbook that someone other than you can follow. Their standard is blunt: if the author of the runbook were unavailable, could a competent engineer who has never seen this solution deploy it correctly from the document alone? Everything you have built is worth nothing to them until that document exists and has been proven by an actual deployment into UAT.

## Steps to Complete

### Task 1: Create the Solution and Add Your Components

1. Navigate to Power Apps and confirm you are in `ODL_User <inject key="DeploymentID" enableCopy="false"></inject>'s Environment`:

   ```
   https://make.powerapps.com
   ```

1. Select **Solutions** from the left navigation pane, then **+ New solution**.

1. Complete the dialog:

   - **Display name:** `Contoso Procurement <inject key="DeploymentID" enableCopy="false"></inject>`
   - **Publisher:** select the default publisher, or create one
   - **Version:** `1.0.0.0`

1. Select **Create**. The solution opens, empty.

1. Select **Add existing**, then **App**, then **Canvas app**, and add `Purchase Approval Hub <inject key="DeploymentID" enableCopy="false"></inject>`.

1. Select **Add existing**, then **Automation**, then **Cloud flow**, and add all three of your flows:

   - `Procurement Approval <inject key="DeploymentID" enableCopy="false"></inject>`
   - `Get Project Budget <inject key="DeploymentID" enableCopy="false"></inject>`
   - `List POs by Project <inject key="DeploymentID" enableCopy="false"></inject>`

1. Select **Add existing**, then **Table**, and add **Approval Log**. When prompted for objects to include, select **Include all components**.

1. Select **Add existing**, then **Chatbot** or **Agent**, and add `Spend Advisor <inject key="DeploymentID" enableCopy="false"></inject>`.

1. Select **Add existing**, then **More**, then **Connection reference**. Hover over a row to reveal its selection circle, and add the four references whose **Name** begins with `new_`:

   - **Dynamics 365 Business Central** - `new_shareddynamicssmbsaas_...`
   - **Dynamics 365 Business Central** - a second one, with a different suffix
   - **Microsoft Dataverse** - `new_sharedcommondataserviceforapps_...`
   - **Standard approvals** - `new_sharedapprovals_...`

   > **Important - two things here differ from what you might expect.**
   >
   > **There are two Business Central references, not one.** Power Platform creates a separate
   > reference per authoring context, and your flows were built in two places. Both must be
   > added here and both must be mapped during the import in Task 6. Miss the second and one
   > agent flow silently loses its connection in UAT: the agent replies, but with no data.
   >
   > **There is no Microsoft Teams reference, and there should not be.** Teams delivery is
   > handled by the Approvals connector, so no separate Teams connection is ever created. If
   > you are looking for one, stop looking.

   > **Note:** Leave any reference whose name begins with `msdyn_`, such as **Content
   > Conversion** and **Dataverse**. Those belong to Copilot Studio's own managed solution and
   > ship with the platform in every environment, so packaging them achieves nothing.

   > **Key insight:** Connection references are the reason a solution can move between environments at all. A flow that holds a direct connection is bound to the credential that created it, so importing it elsewhere would either fail or silently run as the wrong user. A connection reference is a placeholder that gets bound at import time, which is what makes the same package deployable to UAT and production without editing.

### Task 2: Check Dependencies Before You Export

1. Select the **...** on a component, then **Advanced**, then **Show dependencies**.

1. The dialog opens on the **Delete blocked by** tab, which is not the question you are asking.
   Select the **Uses** tab.

   > **Important:** The three tabs answer three different questions. **Delete blocked by** and
   > **Used by** both show what depends on *this* component. Only **Uses** shows what this
   > component depends on, which is what determines whether the solution is complete. Left on
   > the default tab, a solution with genuine missing dependencies reports *"We didn't find
   > anything to show here"*.

1. Check three components, which between them cover the whole dependency surface:

   - the **canvas app**, which depends on the flow it calls
   - any **cloud flow**, which depends on the Approval Log table and its connection references
   - the **Approval Log** table

1. Anything listed under **Uses** that is not already in your solution must be added. Either use
   **Add existing**, or select **Advanced**, then **Add required objects**, which pulls in
   everything missing in one step.

   > **Note:** The canvas app lists only the flow it calls. Its Business Central data sources
   > do not appear, because canvas apps embed connections rather than referencing them, and
   > those are re-bound at import. This is expected, and it is why the app is the component
   > most likely to need attention after the UAT import in Task 6.

   > **Note:** The most commonly missed item is the **Approval Log** table's relationships and views. If you selected **Include all components** in Task 1, they are already present. If you selected only the table, add the missing views now.

### Task 3: Understand What Cannot Be Packaged

1. Confirm for yourself that the AL extension is not in this solution, and cannot be. Search the **Add existing** menus. There is no component type that accepts a Business Central extension.

1. In Visual Studio Code, with your Challenge 01 project open, press **Ctrl+Shift+P**, type `AL: Package`, and press **Enter**.

1. Confirm a `.app` file is produced in the project folder. This is the deployable artefact for the Business Central half of your solution.

   > **Key insight:** Business Central and Power Platform are separate application lifecycle tracks, and this is the point in the lab where that becomes concrete rather than theoretical. Your solution has two deployable artefacts with two different tools, two different admin surfaces, and a mandatory order between them. Deploy the Power Platform solution first and the app will import successfully, then fail at runtime because the API pages it reads do not exist yet in the target Business Central environment. The order is not a preference.

### Task 4: Write the Deployment Runbook

1. On the JumpVM, open Notepad or Visual Studio Code and create a new file.

1. Write a deployment runbook that a competent engineer who has never seen this solution could follow. It must cover, in order:

   - The prerequisites, including which licences the target users need
   - Deploying the `.app` file to the target Business Central environment through **Extension Management**
   - Confirming the custom API endpoint returns data in the target environment before proceeding
   - Importing the managed solution into the target Power Platform environment
   - Which connection references must be mapped and to what
   - Publishing the Copilot Studio agent in the target environment, because it imports as a draft
   - The validation test that proves the deployment worked

1. Save the file as:

   ```
   C:\assets\deployment-runbook.txt
   ```

   > **Note:** Write this before you deploy, not after. You will find out in Task 6 whether it is correct, and a runbook written after a successful deployment quietly omits every step you did from memory.

### Task 5: Export as Managed

1. Return to your solution in Power Apps.

1. Select **Export solution** from the command bar.

1. Select **Publish** to publish all customisations, then **Next**.

1. Review the results of the pre-export check. Resolve any errors. Warnings can be noted and do not block export.

1. Select **Managed** as the export type, then select **Export**.

1. Save the downloaded `.zip` file to `C:\assets`.

   > **Key insight:** Managed is correct for any environment you do not develop in. A managed solution's components cannot be edited in the target, which sounds restrictive and is the point: it guarantees that what runs in UAT is what you exported, so a bug reproduced there is a bug in your source. Unmanaged solutions allow local edits, which means the target drifts from source and nobody can say with confidence what is running.

### Task 6: Deploy to UAT

1. In Power Apps, use the environment picker to switch to `UAT-<inject key="DeploymentID" enableCopy="false"></inject>`.

1. Select **Solutions**, then **Import solution**.

1. Select **Browse**, choose the `.zip` file from `C:\assets`, then select **Next**.

1. On the connection references page, map each reference. For any that show no existing connection, select **+ New connection**, sign in with your lab credentials, then return and select the connection you just created.

   > **Important:** **Both** Business Central connection references must point at your Business
   > Central environment. There are two of them, and the import page lists them under the same
   > display name, so check the row count rather than the label. In a real deployment this would be the customer's UAT Business Central instance. In this lab you have a single Business Central environment, so point it at the environment name you noted in Getting Started. Note this deviation in your runbook, because a real deployment would not share a Business Central environment between dev and UAT.

1. Select **Import** and wait for it to complete. This takes several minutes.

1. When the import finishes, confirm the solution appears in the **Solutions** list with a status of **Installed**.

1. Open the imported `Spend Advisor` agent from within the UAT environment and select **Publish**. It arrived as a draft, as every imported agent does.

### Task 7: Validate the Deployment

Work through this without referring back to earlier challenges. If you get stuck, that tells you something about your runbook.

> **Prerequisite:** Step 5 confirms that a middle-band amount raises **two** approvals, which
> means Challenge 03 Tasks 4 and 7 must be complete. If you ran short of time there and built
> only Tier 1, go back and finish them before starting this task. Otherwise you will see one
> approval instead of two and have no way to tell whether your deployment failed or your flow
> was never finished - which is precisely the ambiguity a validation step exists to remove.

1. In Business Central, create a purchase order for approximately 30,000, charged to project `INFRA-2026`, department `IT`.

1. Still in Business Central, open **Project Budgets** and confirm the `INFRA-2026` row's
   **Spent Amount** has already grown by roughly 30,000, without you doing anything to it.

   > **Important:** This is a deployment check, not a housekeeping step. Committed spend is
   > maintained by the event subscribers you wrote in Challenge 01 Task 5, and this is the
   > first time they have run in the target environment.
   >
   > If the figure has not moved, the extension deployed but its subscribers are not firing.
   > Press **Recalculate Spend** to unblock yourself, then treat it as a deployment failure:
   > every figure the app and the agent report from here on would be a snapshot frozen at the
   > moment somebody last pressed that button, and nothing would appear to be wrong.

1. In the **UAT** environment, open the imported Purchase Approval Hub and confirm the new purchase order appears with a budget indicator.

1. Ask the Spend Advisor agent in UAT what the remaining budget for `INFRA-2026` is, and confirm the figure matches Business Central.

1. Select **Approve** in the app and complete both approval tiers in Teams. Confirm two tiers are requested, because the amount falls in the middle band.

1. In Business Central, confirm the purchase order was updated.

1. In the UAT environment, open the **Approval Log** table and confirm the run wrote one row per tier, sharing a single **Run ID**.

1. Return to `C:\assets\deployment-runbook.txt` and correct every step you got wrong or had to work out during this task.

   > **Key insight:** The corrections you just made are the actual output of this challenge. A runbook that survives its first real execution unchanged is almost always a runbook that was written from the deployment rather than for it. The gap you just closed is the gap that would otherwise have been discovered by a colleague at 2am during a production window.

## Success Criteria

- [ ] A solution named `Contoso Procurement <inject key="DeploymentID" enableCopy="false"></inject>` contains the canvas app, three flows, the Approval Log table, the agent, and all connection references
- [ ] The dependency check passes with no missing components
- [ ] A `.app` file has been produced from Visual Studio Code
- [ ] `C:\assets\deployment-runbook.txt` exists and covers both deployment tracks in the correct order
- [ ] The solution exports as **Managed** with no pre-export errors
- [ ] The solution imports into `UAT-<inject key="DeploymentID" enableCopy="false"></inject>` with all connection references mapped, and shows as **Installed**
- [ ] The agent has been published in the UAT environment
- [ ] A 30,000 purchase order completes two approval tiers end to end using the UAT-deployed components
- [ ] The Approval Log in UAT contains one row per tier sharing a **Run ID**
- [ ] The runbook has been corrected based on what the deployment actually required

## Additional Resources

- [Export solutions](https://learn.microsoft.com/en-us/power-platform/alm/export-solutions)
- [Import and update solutions](https://learn.microsoft.com/en-us/power-platform/alm/import-update-export-solutions)
- [Connection references](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/create-connection-reference)
- [Application lifecycle management for Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-application-lifecycle-management)
- [Publish a Business Central extension](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-publish-code-customization)

## Congratulations - Hack in a Day Complete

You started with a Business Central Purchase Order page that had nowhere to record a project, and a finance team reconciling budgets in a spreadsheet once a month. You finished with project spend tracked inside the ERP itself, an approval interface that shows budget consequences before the decision rather than after it, routing that enforces Contoso's authority levels without anyone having to remember them, an audit trail that records the approvals that did not happen as well as the ones that did, an advisory agent that answers questions from live data and refuses to invent an answer when it has none, and a documented deployment that a colleague could execute without you.

Along the way you learned some things that generalise well beyond this lab: that extension fields are invisible to standard APIs, that delegation warnings are a production problem disguised as a blue underline, that a preview control can be withdrawn between design and delivery, and that the hardest part of an AI agent is making it decline.

## Support Contact

The CloudLabs support team is available 24/7, 365 days a year, via email and live chat to ensure seamless assistance at any time.

Learner Support Contacts:

- Email Support: cloudlabs-support@spektrasystems.com
- Live Chat Support: https://cloudlabs.ai/labs-support

## Happy Hacking!!
