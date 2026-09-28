# Challenge 01 (Express): Deploy the Business Central Extension

## Introduction

Business Central's Purchase Order page has no project tracking fields. There is no Project Code, no Department against the purchase, and no budget category. Finance has asked for every purchase to be tagged before it can be approved, and right now there is nowhere to put the tag. This is why Contoso's budget tracking lives in a spreadsheet that is reconciled once a month and is wrong for the other twenty-nine days.

In this express version of Challenge 01 the AL extension has already been written for you. Your job is to deploy it, understand what it does, and prove it works end to end, because everything in the next four challenges reads the data it exposes.

That last part matters more than it sounds. Business Central's standard `purchaseOrders` API does not return fields that an extension added. It returns the fields Microsoft shipped, and nothing else. The extension you are about to deploy therefore also publishes a **custom API page**, which is the supported way to expose extension data to Power Platform. You will verify that endpoint returns live data before moving on, because Challenge 02 connects to it and a silent failure here looks exactly like a Power Apps problem two hours later.

> **Note:** If you would rather write the AL yourself, use [challenge-1.md](challenge-1.md) instead. The two produce an identical extension. This version trades the coding for time.

## Challenge Objectives

- Understand what the extension adds to Business Central and why each object exists
- Upload and deploy a per-tenant extension through Extension Management
- Verify the new fields appear on the Purchase Order page
- Create a project budget and tag purchase orders against it
- Confirm committed spend maintains itself automatically
- Prove the custom API returns live data to Power Platform

## Duration

35 minutes

## Your Assignment

> Finance signed off on the field names and will not accept variations, because the monthly reporting pack is already written against them. The names are Project Code, Department and Budget Category. The integration team needs your API endpoint working by lunchtime so they can start building against it. They have asked you to prove it returns data before you hand it over, because the last extension they were given returned an empty array for a week before anyone noticed.

## Steps to Complete

### Task 1: Review What You Are Deploying

You are not expected to memorise this, but you will be asked in later challenges why a given number appears where it does, and the answer is usually here.

1. On the JumpVM, open **File Explorer** and browse to:

   ```
   C:\assets
   ```

1. Confirm the folder contains:

   ```
   Contoso_BC Procurement Extension_1.0.0.0.app
   ```

1. Read through what that package contains before you deploy it:

   | Object | ID | What it does |
   |---|---|---|
   | `Purchase Header Ext` (table extension) | 50100 | Adds **Project Code**, **Department** and **Budget Category** to the standard Purchase Header table |
   | `Purchase Order Ext` (page extension) | 50100 | Surfaces those three fields on the **General** FastTab of the Purchase Order page |
   | `Project Budget` (table) | 50100 | Holds a budget per project and department, with Budget, Spent and Remaining amounts |
   | `Project Budget List` (page) | 50100 | The list page you will use to create a budget, with a **Recalculate Spend** action |
   | `Project Budget Mgmt` (codeunit) | 50100 | Totals committed spend across purchase orders, and keeps it current through event subscribers |
   | `Purchase Order API` (page) | 50101 | Custom API exposing purchase orders **including** the three new fields |
   | `Project Budget API` (page) | 50102 | Custom API exposing project budgets |
   | `BC Procurement` (permission set) | 50100 | Grants access to the new table |

   > **Key insight:** That last row is not paperwork. Business Central refuses to accept a per-tenant extension that declares a table without a matching permission set, and rejects the upload with `PTE0004: Table 50100 'Project Budget' is missing a matching permission set`. Worth knowing because the check is applied on **upload** and not when publishing straight from Visual Studio Code, so an extension can appear to work in development and fail the moment it is deployed properly.

   > **Key insight:** The codeunit contains event subscribers on the Purchase Line and Purchase Header tables. Without them, committed spend would only change when somebody pressed **Recalculate Spend**, and every figure the app and the AI agent report in later challenges would be frozen at whatever it was at that moment. You will test this in Task 5.

### Task 2: Upload and Deploy the Extension

1. Open Business Central and confirm you are in the environment you created in Getting Started, `BC-ODL-<inject key="DeploymentID" enableCopy="false"></inject>`, and the company **CRONUS USA, Inc.**

1. Open **Tell Me** (**Alt+Q**), search for `Extension Management`, and open it.

1. Select **...** (More options) from the action bar, then **Manage**, then **Upload Extension...**.

1. In the **Upload And Deploy Extension** dialog:

   - **Select .app file:** browse to `C:\assets\Contoso_BC Procurement Extension_1.0.0.0.app`
   - **Deploy to:** `Current version`
   - **Language:** `English (United States)`
   - **Schema Sync Mode:** `Add`
   - Turn the acceptance toggle **on**

   > **Note:** **Deploy** stays greyed out until you turn that toggle on. This catches nearly everyone.

   > **Note:** `Add` is correct here. `Force Sync` is for destructive schema changes, such as removing or retyping a field, and it can delete data.

1. Select **Deploy**.

1. Open **Tell Me**, search for `Extension Installation Status`, and open it. Your extension appears with **Operation Type** `Upload`. Select **Refresh** until **Status** changes from `InProgress` to `Completed`.

   Deployment usually takes one to two minutes.

1. If **Status** reads `Failed`, select the row, then **View Details**, and read the **Error Details** field.

   > **Important:** The most likely cause is an earlier attempt. Every upload registers the combination of App ID and version with Microsoft's service, **including uploads that failed validation**, so re-uploading the same file is rejected with *"A different .app file with the same App ID and version has already been uploaded to our service."* This is not a permissions problem and signing in again will not help. Contact your lab support with the error text.

   > **Important:** If you see `AVS0109: The per-tenant extension (or one of its dependencies) cannot be deployed ... conflicting with currently installed apps`, an earlier copy of this extension is already published on the environment. Go to **Extension Management**, find **BC Procurement Extension**, **Uninstall** it and then **Unpublish** it, and upload again.
   >
   > When you uninstall, leave **Delete Extension Data** switched **off**. Turning it on removes every Project Budget row and clears Project Code, Department and Budget Category from every purchase order.

### Task 3: Confirm the Fields Are Live

1. Use **Tell Me** to search for `Purchase Orders`, and open any existing order.

1. Confirm the **General** FastTab now shows **Project Code**, **Department** and **Budget Category** at the bottom.

   If they are not there, the extension deployed but the page extension did not apply. Close and reopen the page, then re-check **Extension Installation Status**.

### Task 4: Tag Purchase Orders and Create a Budget

1. On the purchase order you have open, set the following and note its number:

   - **Project Code:** `INFRA-2026`
   - **Department:** `IT`
   - **Budget Category:** `Capital`

1. Open a second purchase order and set the same **Project Code** and **Department**, so that two orders are charged to the same project. Note its number too.

1. Use **Tell Me** to search for `Project Budgets` and open the list.

1. Select **New** and create a record:

   - **Project Code:** `INFRA-2026`
   - **Department:** `IT`
   - **Budget Amount:** `50000`

1. With that row selected, choose the **Recalculate Spend** action.

1. Confirm **Spent Amount** now shows the combined total of your two purchase orders, and **Remaining Amount** shows 50,000 minus that figure.

   > **Note:** If Spent Amount stays at zero, the most likely cause is a mismatch between the Project Code on the purchase orders and the one on the budget record. They must match exactly, including case.

### Task 5: Confirm Committed Spend Maintains Itself

This takes two minutes and it is the single most valuable check in this challenge.

1. Open one of the two purchase orders you tagged.

1. Change the **Quantity** on one of its lines, then click away from the line so the change commits.

1. Return to **Project Budgets** and look at the `INFRA-2026` row. Do **not** press **Recalculate Spend**.

1. Confirm **Spent Amount** has already changed to reflect the new total.

   > **Key insight:** That is the event subscribers doing their job. `Spent Amount` is a stored field rather than a live calculation, so without them it would be correct only until the next purchase order changed, and stale from then on.
   >
   > A stale number is not an obvious bug. It came from the database, through a real API call, and it is displayed with total confidence by the app you build in Challenge 02 and quoted by the agent you build in Challenge 04. It is simply wrong. Challenge 04 is built on the premise that an advisor which invents a figure is worse than no advisor, and a stale figure fails that test just as badly.
   >
   > If the number does not move on its own, stop and raise it with your lab support before continuing. Every figure in the remaining challenges depends on it.

### Task 6: Prove the API Returns Data

Your API page is published, but you cannot check it by pasting the URL into a browser tab. `api.businesscentral.dynamics.com` accepts only an OAuth 2.0 bearer token. It does not accept the cookie from your Business Central session and it will not show you a sign-in prompt. A browser request returns this and nothing else:

```xml
<error xmlns="http://docs.oasis-open.org/odata/ns/metadata">
  <code>Unauthorized</code>
  <message>The credentials provided are incorrect</message>
</error>
```

So you will verify the endpoint the way the rest of this lab consumes it, through the Business Central connector, which performs the OAuth handshake for you.

1. Open [Power Automate](https://make.powerautomate.com) and confirm your environment is selected in the top-right picker.

1. Select **+ Create**, then **Instant cloud flow**, name it `API Check <inject key="DeploymentID" enableCopy="false"></inject>`, choose **Manually trigger a flow**, and select **Create**.

1. Add a **New step**, search for `Business Central`, and choose **Find records (V3)**.

1. Set **Environment** to your environment and **Company** to `CRONUS USA, Inc.`

1. In the **API category** picker, look for your custom entity. It appears as `contoso/procurement/v1.0` with table `purchaseOrders`.

   > **Key insight:** If your entity is not in this list, the API page did not publish. Go back to **Extension Installation Status** and confirm the upload reads `Completed`.

1. Run the flow and open the run history. Inspect the JSON body of the action's output.

1. Confirm the output includes your two tagged purchase orders, and that each one carries a populated `projectCode` field.

1. Now add a second action using the **standard** Business Central connector table `Purchase Orders` rather than your custom entity, and run the flow again.

1. Compare the two outputs. The standard one has no `projectCode` at all.

   > **Key insight:** This is the proof the integration team asked for. The standard `purchaseOrders` API was compiled before your fields existed and knows nothing about them. Extension fields need a custom API page, every time. Keep this flow, because Challenge 04 calls the same entity.

1. For reference, the URL your API page exposes has this shape. You cannot open it in a browser, but you will see it in the connector and in the flow's run history:

   ```
   https://api.businesscentral.dynamics.com/v2.0/<environmentName>/api/contoso/procurement/v1.0/companies(<company-id>)/purchaseOrders
   ```

   > **Note:** `<company-id>` is a GUID, not the company name. You cannot read it from the Business Central UI. The connector resolves it for you, which is another reason to verify through the connector rather than by hand.

## Success Criteria

- [ ] **Extension Installation Status** shows **BC Procurement Extension** with **Status** `Completed`
- [ ] **Project Code**, **Department** and **Budget Category** appear on the Purchase Order page
- [ ] The **Project Budgets** list page is reachable through Tell Me and has a working **Recalculate Spend** action
- [ ] Two purchase orders are tagged `INFRA-2026` / `IT`
- [ ] A Project Budget record for `INFRA-2026` / `IT` shows a non-zero **Spent Amount**, and a **Remaining Amount** equal to 50,000 minus that figure
- [ ] Changing a purchase order line quantity updates **Spent Amount** without pressing **Recalculate Spend**
- [ ] Your custom entity appears in the Business Central connector and returns a populated `projectCode`
- [ ] You can explain, without looking it up, why the standard `purchaseOrders` API does not return `projectCode`
- [ ] You can explain why a table in a per-tenant extension needs a permission set

## Additional Resources

- [Publishing an extension](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-extensions-install-uninstall)
- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object)
- [Developing a custom API](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-develop-custom-api)
- [API page type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-api-pagetype)

Now, click **Next** to continue to **Challenge 02**.
