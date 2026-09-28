# Challenge 03: Multi-Level Approval Routing

## Introduction

The Purchase Approval Hub shows an approver everything they need to make a decision, but the buttons do nothing. Pressing Approve raises a notification and changes nothing in Business Central, and no record is kept of who decided what.

Contoso's approval policy is not a single step. Purchases under 10,000 need one approval from the requester's manager. Between 10,000 and 50,000, Finance must also sign off. Above 50,000, the CFO is required as well. Each tier must happen in order, a rejection at any tier stops the process immediately, and the auditors require a durable record of every decision including the ones that stopped things.

In this challenge you will build that routing in Power Automate, capture decisions through Teams approval cards, write the audit trail to Dataverse, and update the purchase order back in Business Central through the API you built in Challenge 01.

## Challenge Objectives

- Create a Dataverse table to hold the approval audit trail
- Build a Power Automate flow that Power Apps can call with typed inputs
- Route by amount through one, two or three sequential approval tiers
- Capture approver decisions through Teams and record each one
- Write the decision back to Business Central and stop cleanly on rejection

## Duration

55 minutes

## Your Assignment

> Internal Audit has one requirement and they have stated it twice. Every approval decision must produce a record, including rejections, and including the tiers that never ran because an earlier tier rejected. Their exact words were that a purchase order which disappears from the queue with no explanation is worse than one that is wrongly approved, because at least the wrong approval leaves a trail.

## Steps to Complete

### Task 1: Create the Approval Log Table in Dataverse

1. Navigate to Power Apps and confirm you are in `ODL_User <inject key="DeploymentID" enableCopy="false"></inject>'s Environment`:

   ```
   https://make.powerapps.com
   ```

1. Select **Tables** from the left navigation pane, then **+ New table**. Under the
   **Start from a blank table** heading, select **Add columns and data**.

   > **Note:** **Start from a blank table** is a heading, not a clickable option. The two
   > choices beneath it are **Describe new tables**, which builds the table from a Copilot
   > prompt, and **Add columns and data**, which opens the visual designer. Use the second so
   > you set the column types yourself.

1. The designer opens on a card named `Table1`. Select that name and change it to:

   ```
   Approval Log
   ```

1. The first column you create becomes the table's **primary column**, so create `PO Number`
   first and the rest will hang off it.

   > **Note:** Dataverse no longer adds a default **Name** column for you. Whichever column
   > you define first takes that role, which is why `PO Number` leads the list below.

1. Select **+ New**, then **Column**, and add each of the following. Use the exact display names, because later steps reference them:

   | Display name | Data type | Notes |
   |---|---|---|
   | `PO Number` | Text | The Business Central purchase order number |
   | `PO Amount` | Currency | Total including VAT |
   | `Project Code` | Text | Copied from the purchase order |
   | `Approval Tier` | Whole number | 1, 2 or 3 |
   | `Approver Email` | Text | Who was asked |
   | `Decision` | Choice | Values: `Approved`, `Rejected`, `Not Reached` |
   | `Decision Comments` | Multiline text | The approver's comment |
   | `Run ID` | Text | Correlates all rows from one flow run |

   > **Key insight:** The `Not Reached` choice is what satisfies Audit's requirement. When Tier 1 rejects, Tiers 2 and 3 never run, and without an explicit row saying so the audit trail is silent about them. Silence is ambiguous: it could mean not required, or it could mean the flow crashed. An explicit `Not Reached` row removes the ambiguity, and it costs you one extra action in the flow.

1. Select **Save and exit** and wait for the table to finish provisioning.

1. Return to **Tables**, select the **Custom** tab, and confirm **Approval Log** is listed.
   If it is not there, the table was not saved and only existed as a draft in the designer.

### Task 2: Create the Flow with a Power Apps Trigger

1. Navigate to Power Automate:

   ```
   https://make.powerautomate.com
   ```

1. Confirm the environment picker shows `ODL_User <inject key="DeploymentID" enableCopy="false"></inject>'s Environment`.

1. Select **+ Create**, then **Instant cloud flow**.

1. Name the flow exactly:

   ```
   Procurement Approval <inject key="DeploymentID" enableCopy="false"></inject>
   ```

1. Under **Choose how to trigger this flow**, select **Power Apps**, then select **Create**.

   > **Important:** Select the **Power Apps** trigger, not **When an HTTP request is received**. Only the Power Apps trigger can be attached to a button in Power Apps Studio and called by name. An HTTP trigger would require you to build and manage the request yourself, and it cannot be selected from the Power Apps action list.

1. On the **PowerApps (V2)** trigger, select **+ Add an input** and add each of the following in this exact order. The order matters, because Power Apps passes arguments positionally:

   | Type | Name |
   |---|---|
   | Text | `PONumber` |
   | Number | `POAmount` |
   | Text | `VendorName` |
   | Text | `ProjectCode` |
   | Text | `Decision` |
   | Text | `RequestorEmail` |
   | Text | `POId` |

   > **Important:** `POId` carries the purchase order's `id` GUID, which Task 8 needs to write
   > the decision back to Business Central. It is last in the list because Power Apps passes
   > arguments positionally, so adding it at the end leaves the other five in place.

### Task 3: Initialise the Flow Variables

1. Select **+ New step**, search for `Initialize variable`, and add it.

1. Configure it:

   - **Name:** `varTier1Outcome`
   - **Type:** `String`
   - **Value:** leave empty

1. Add two more **Initialize variable** actions the same way:

   | Name | Type |
   |---|---|
   | `varTier2Outcome` | String |
   | `varTier3Outcome` | String |

1. Add a fourth:

   - **Name:** `varTiersRequired`
   - **Type:** `Integer`
   - **Value:** `1`

### Task 4: Work Out How Many Tiers Are Needed

1. Select **+ New step** and add a **Condition** action. Rename it to `Check if two tiers needed`.

1. Configure the condition:

   - Left: the `POAmount` value from the trigger, using the dynamic content picker
   - Operator: **is greater than or equal to**
   - Right: `10000`

1. In the **If yes** branch, add a **Set variable** action:

   - **Name:** `varTiersRequired`
   - **Value:** `2`

1. Still inside **If yes**, add a nested **Condition** named `Check if three tiers needed`:

   - Left: `POAmount`
   - Operator: **is greater than**
   - Right: `50000`

1. In the nested **If yes** branch, add another **Set variable**:

   - **Name:** `varTiersRequired`
   - **Value:** `3`

1. Leave both **If no** branches empty. The variable already defaults to `1`.

   > **Key insight:** Working out the tier count once, up front, is much easier to reason about than repeating the amount test at each tier. If Contoso later changes the thresholds, you edit one condition instead of three, and there is no way for the tiers to disagree with each other about how many are required.

### Task 5: Build the Tier 1 Approval

1. After the condition block, select **+ New step**, search for `Approvals`, and select **Start and wait for an approval**.

1. Configure it:

   - **Approval type:** `Approve/Reject - First to respond`
   - **Title:**

     ```
     Tier 1 approval required for PO
     ```

     Then use the dynamic content picker to append the `PONumber` value.

   - **Assigned to:** <inject key="AzureAdUserEmail"></inject>

     > **Note:** In a real deployment this would be a manager lookup against Entra ID. For this lab you are every approver, so that you can complete all three tiers yourself and see the full chain.

   - **Details:** build a summary using dynamic content, for example the vendor name, the amount, and the project code

1. Add a **Set variable** action after it:

   - **Name:** `varTier1Outcome`
   - **Value:** the **Outcome** field from the approval action

1. Select **+ New step**, search for `Dataverse`, and select **Add a new row**.

1. Set **Table name** to `Approval Logs`, then map the columns:

   | Column | Value |
   |---|---|
   | `PO Number` | `PONumber` from the trigger |
   | `PO Amount` | `POAmount` from the trigger |
   | `Project Code` | `ProjectCode` from the trigger |
   | `Approval Tier` | `1` |
   | `Approver Email` | <inject key="AzureAdUserEmail"></inject> |
   | `Decision` | see the note below - this one is not straightforward |
   | `Decision Comments` | the **Comments** field from the approval |
   | `Run ID` | expression: `workflow()['run']['name']` |

   > **Note:** To enter the expression, select the **Run ID** field, choose the **Expression** tab in the dynamic content panel, paste `workflow()['run']['name']`, and select **OK**.

   > **Important - the `Decision` column needs a number, not a word.** `Decision` is a
   > **Choice** column, and Dataverse stores choices as integers rather than as their labels.
   > Three things follow from that, and all three will bite you at runtime rather than while
   > you build:
   >
   > 1. The field renders as a dropdown offering `Approved` / `Rejected` / `Not Reached`. It
   >    will not accept a variable directly, so you have to select **Enter custom value**.
   > 2. The approval action's **Outcome** returns `Approve` and `Reject` - present tense, no
   >    "d" - so it never matches the labels anyway.
   > 3. The underlying value is an integer that Dataverse generated when you created the
   >    table, and **it is different in every environment**.
   >
   > Find your two numbers first. Select `Approved` from the dropdown, open the action's
   > **Code view**, and read the value of `item/..._decision`. Repeat for `Rejected`. They
   > will be large numbers such as `825790000` and `825790001`.
   >
   > Then set **Decision** with **Enter custom value**, switch to the **Expression** tab, and
   > enter the following, substituting your own two numbers:
   >
   > ```
   > if(equals(variables('varTier1Outcome'), 'Approve'), 825790000, 825790001)
   > ```
   >
   > No quotation marks around the numbers. If you pass a string, the run fails with
   > *"Input parameter 'item/..._decision' is required to be of type 'Integer/int32'"* - and
   > only after you have already responded to the approval in Teams.

   > **Note:** Power Automate will wrap **Add a new row** in a **For each** loop as soon as
   > you reference **Comments**, because an approval returns a collection of responses. That
   > is expected. Leave the loop in place.

### Task 6: Stop Cleanly on Rejection

1. Select **+ New step** and add a **Condition** named `Tier 1 rejected`.

1. Configure it:

   - Left: the `varTier1Outcome` variable
   - Operator: **is equal to**
   - Right: `Reject`

1. In the **If yes** branch, add a **Dataverse** action, **Add a new row**, to record the tiers that will not run:

   | Column | Value |
   |---|---|
   | `PO Number` | `PONumber` |
   | `Approval Tier` | `2` |
   | `Decision` | the integer for `Not Reached`, found the same way as in Task 5 |
   | `Decision Comments` | `Rejected at Tier 1` |
   | `Run ID` | `workflow()['run']['name']` |

1. Still in **If yes**, add a **Terminate** action:

   - **Status:** `Succeeded`

   > **Key insight:** Terminate with `Succeeded`, not `Failed`. A rejection is a correct outcome of a working process, not an error. Marking it `Failed` would fill the run history with red entries that hide genuine faults, and would trigger failure alerts for something that worked exactly as designed.

1. Leave the **If no** branch empty for now. The flow continues past the condition when Tier 1 approves.

### Task 7: Build Tiers 2 and 3

1. After the condition block, add a new **Condition** named `Tier 2 required`:

   - Left: the `varTiersRequired` variable
   - Operator: **is greater than or equal to**
   - Right: `2`

1. In the **If yes** branch, add a second **Start and wait for an approval** action, configured like Tier 1 but with the title referring to **Tier 2** and Finance.

1. Still in **If yes**, add a **Set variable** for `varTier2Outcome` from that approval's **Outcome**.

1. Still in **If yes**, add a **Dataverse Add a new row** action recording Tier `2`, the same way you did for Tier 1.

1. Still in **If yes**, add a nested **Condition** checking whether `varTier2Outcome` equals `Reject`. Inside its **If yes**, add a **Terminate** with status `Succeeded`.

1. After the Tier 2 condition block, repeat the whole pattern for Tier 3:

   - Condition: `varTiersRequired` **is equal to** `3`
   - A third **Start and wait for an approval**, titled for the CFO
   - A **Set variable** for `varTier3Outcome`
   - A **Dataverse Add a new row** recording Tier `3`

### Task 8: Write the Decision Back to Business Central

1. After all three tier blocks, select **+ New step**, search for `Business Central`, and select **Update record (V3)**.

1. Configure it:

   - **Environment:** the Business Central environment name you noted in Getting Started
   - **Company:** the Business Central company name you noted in Getting Started
   - **API category:** `contoso/procurement/v1.0`
   - **Table name:** `purchaseOrders`
   - **Row id:** the `POId` value from the trigger, using the dynamic content picker

   > **Important:** The Row id must be the record's `id` GUID, which is the `SystemId` your API page exposes, not the human-readable PO number. This is the reason Challenge 01 set `ODataKeyFields = SystemId`. If you pass the PO number here, the action returns a not-found error.

   > **Note:** **API category** is its own dropdown, listing every API group published in the
   > environment. `contoso/procurement/v1.0` is your Challenge 01 API page. Leave it on the
   > default `v2.0` and the **Table name** list will offer the standard `purchaseOrders`
   > instead, which has no `projectCode` and is not the table you extended.

1. Leave the field values empty for now and select **Show all** under **Advanced parameters**
   to see what the action can write.

   > **Important:** Do **not** write the approval outcome into **Budget Category**. That field
   > holds the spend classification you set in Challenge 01, such as `Capital`, and
   > overwriting it destroys data the rest of the lab depends on. The extension has no
   > approval-status field, so there is nowhere correct to put the decision yet.
   >
   > The durable record of the decision is the Dataverse **Approval Log** rows you wrote in
   > Tasks 5 to 7. If you want the outcome visible inside Business Central as well, the right
   > fix is to add an `Approval Status` field to the Purchase Header in Challenge 01 and write
   > to that here.

1. Select **+ New step** and add a **Post message in a chat or channel** action from the Microsoft Teams connector.

1. Configure it to post to yourself with a message confirming the purchase order was fully approved, including the PO number and vendor from the trigger.

1. Select **Save**.

### Task 9: Connect the Flow to the Power App

1. Return to Power Apps and open `Purchase Approval Hub <inject key="DeploymentID" enableCopy="false"></inject>` for editing.

1. Select the `btnApprove` button.

1. Select **Power Automate** from the left pane, then **+ Add flow**, and choose `Procurement Approval <inject key="DeploymentID" enableCopy="false"></inject>`.

1. Set the button's **OnSelect** property to the following. The arguments must appear in the same order you defined the trigger inputs:

   ```
   Set(
       varFlowResult,
       'ProcurementApproval'.Run(
           varSelectedPO.number,
           varSelectedPO.totalAmount,
           varSelectedPO.vendorName,
           varSelectedPO.projectCode,
           "Approved",
           User().Email,
           varSelectedPO.id
       )
   );
   Notify("Approval submitted for " & varSelectedPO.number, NotificationType.Success)
   ```

   > **Note:** The flow name in the formula has spaces and the Deployment ID removed, because Power Apps strips those when it creates the reference. Use the name exactly as it appears in the **Power Automate** pane after you add the flow, which may differ slightly from the formula above.

1. Set the `btnReject` button's **OnSelect** to the same formula but with `"Rejected"` in place of `"Approved"`.

1. Select **Save**, then **Publish**.

### Task 10: Test All Three Tiers

1. In Business Central, create or edit three purchase orders so that you have one in each band. Set the same **Project Code** of `INFRA-2026` and **Department** of `IT` on all three:

   | Test | Target amount | Expected tiers |
   |---|---|---|
   | A | under 10,000 | Tier 1 only |
   | B | between 10,000 and 50,000 | Tiers 1 and 2 |
   | C | over 50,000 | Tiers 1, 2 and 3 |

1. Open the published Purchase Approval Hub app.

1. Select purchase order A and choose **Approve**.

1. Open Microsoft Teams and find the approval card in your **Approvals** app or your activity feed. Select **Approve** and submit.

1. Return to Power Automate, open the flow, and check the run history. Confirm the run completed and only one approval action ran.

1. Repeat for purchase order B. Confirm two approval cards arrive in sequence, and that the second only appears after you respond to the first.

1. Repeat for purchase order C, confirming three cards.

1. Now run a rejection test. Select any purchase order, choose **Approve** in the app, and then **Reject** the Tier 1 card in Teams.

1. In Power Apps, select **Tables**, open **Approval Log**, and select **Edit** to view the data.

1. Confirm the rejected run produced two rows: one for Tier 1 with `Rejected`, and one for Tier 2 with `Not Reached`. Confirm both share the same `Run ID`.

   > **Key insight:** The shared Run ID is what makes this table usable by Audit. Without it, a table of individual decisions cannot be reassembled into the history of a single purchase order, because the same PO can legitimately go through the process more than once after a rejection and resubmission.

## Success Criteria

- [ ] A Dataverse table named **Approval Log** exists with all eight columns, including a `Not Reached` choice on **Decision**
- [ ] A flow named `Procurement Approval <inject key="DeploymentID" enableCopy="false"></inject>` exists with a **PowerApps (V2)** trigger and six typed inputs
- [ ] A purchase order under 10,000 triggers exactly one approval
- [ ] A purchase order between 10,000 and 50,000 triggers two, in sequence
- [ ] A purchase order over 50,000 triggers three, in sequence
- [ ] Rejecting at Tier 1 terminates the flow with status **Succeeded**, not **Failed**
- [ ] A rejected run writes both a `Rejected` row and a `Not Reached` row sharing one **Run ID**
- [ ] A fully approved purchase order is updated in Business Central and a Teams message is posted
- [ ] The Approve and Reject buttons in the app call the flow and no longer show the placeholder notification

## Additional Resources

- [Create approval flows in Power Automate](https://learn.microsoft.com/en-us/power-automate/modern-approvals)
- [Sequential approvals](https://learn.microsoft.com/en-us/power-automate/sequential-modern-approvals)
- [Call a flow from a canvas app](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/using-logic-flows)
- [Workflow function reference](https://learn.microsoft.com/en-us/azure/logic-apps/workflow-definition-language-functions-reference#workflow)

Now, click **Next** to continue to **Challenge 04**.
