# Challenge 02: Build the Purchase Approval Hub

## Introduction

Your extension now tracks project spend inside Business Central, and your API exposes it. But an approver still has to open Business Central, find the purchase order, note the project code, open the Project Budgets list separately, and do the arithmetic in their head. In practice that means approvals happen without budget context, which is the exact problem Finance asked you to solve.

In this challenge you will build the Purchase Approval Hub, a Power Apps canvas app that puts the purchase order and its budget position on one screen. An approver sees the vendor, the amount, the project, and a colour-coded bar showing how much of that project's budget is already committed, without navigating anywhere.

You will also meet delegation, which is the single most common reason a Power App works perfectly in a demo with ten records and fails silently in production with ten thousand. Understanding it is worth more than the app you build here.

## Challenge Objectives

- Connect a Power Apps canvas app to your custom Business Central API
- Build a gallery of purchase orders showing vendor, amount and project
- Calculate budget consumption per project and render it as a colour-coded indicator
- Recognise a delegation warning and decide whether it matters
- Build a details pane that responds to the selected purchase order

## Duration

50 minutes

## Your Assignment

> The procurement lead has told you plainly that approvers will not use anything that takes more than one screen. If they have to click into a second page to find out whether the project can afford the purchase, they will keep approving from their inbox without looking, which is how the current process works and why Finance is unhappy. One screen, budget visible, no navigation.

## Steps to Complete

### Task 1: Create the App and Connect to Business Central

1. Navigate to Power Apps:

   ```
   https://make.powerapps.com
   ```

1. Confirm the environment picker in the top-right corner shows `ODL_User <inject key="DeploymentID" enableCopy="false"></inject>'s Environment`.

   > **Important:** If it shows **Default** or another participant's environment, change it now. Everything you build from here must live in your own environment or Challenge 05 cannot package it.

1. Select **+ Create** from the left navigation pane, then under **Start from design**
   select **Create from blank** (labelled **Canvas app**).

1. When asked what size to use, select **Tablet**.

1. Power Apps Studio opens on an unnamed app. Select **Save** from the toolbar and name it
   exactly:

   ```
   Purchase Approval Hub <inject key="DeploymentID" enableCopy="false"></inject>
   ```

   > **Note:** The app is named when you first save it, not before it is created.

1. In Power Apps Studio, select **Data** from the left pane, then **Add data**.

1. Search for `Business Central` and select the **Dynamics 365 Business Central** connector.

1. Select the connection you created during Getting Started, or sign in with your lab credentials to create one.

1. When prompted to choose your data:

   - **Environment:** the Business Central environment name you noted in Getting Started
   - **Company:** the Business Central company name you noted in Getting Started

1. From the table list, select both of the following, then select **Connect**:

   - `purchaseOrders` from the **contoso / procurement** API group
   - `projectBudgets` from the **contoso / procurement** API group

   > **Important:** The connector also lists a `purchaseOrders` table from the standard **v2.0** API group. Do not select that one. It looks identical in the picker and it does not contain your Project Code field. If you only see the standard tables and not the **contoso / procurement** group, your API pages did not publish. Return to Challenge 01 Task 7 and republish before continuing.

1. Look at the two entries now listed in the **Data** pane. Power Apps has not named them
   `purchaseOrders` and `projectBudgets`. It has named them:

   ```
   purchaseOrders (contoso/procurement/v1.0)
   projectBudgets (contoso/procurement/v1.0)
   ```

   Every formula in this challenge, and in Challenge 03, refers to them by their short names.
   Before you write any of those formulas you have to make the short names mean something.

1. Select **App** at the top of the tree view on the left, choose **Formulas** from the
   property dropdown, and set it to:

   ```
   purchaseOrders = 'purchaseOrders (contoso/procurement/v1.0)';
   projectBudgets = 'projectBudgets (contoso/procurement/v1.0)';
   ```

1. Confirm the formula bar accepts it without a red underline.

   > **Key insight:** A data source name containing spaces, slashes or brackets has to be
   > wrapped in single quotes everywhere it appears, which would make every formula in this
   > challenge unreadable. These two lines are **named formulas**: aliases evaluated once and
   > usable anywhere in the app. Connector data sources cannot be renamed, so aliasing is the
   > supported way to get a clean name. Skip this step and every later formula fails with
   > *"Name isn't valid"*, and the error will point at your formula rather than at the
   > mismatch that actually caused it.

### Task 2: Build the Purchase Order Gallery

1. Select **Insert** from the left pane, then **Gallery**, then **Blank vertical**.

1. With the gallery selected, in the right-hand **Properties** pane set **Data source** to `purchaseOrders`.

1. Rename the gallery. In the tree view on the left, double-click its name and change it to:

   ```
   galPurchaseOrders
   ```

1. Select the gallery, and in the formula bar set the **Items** property to:

   ```
   SortByColumns(
       Filter(purchaseOrders, status = "Open"),
       "documentDate",
       SortOrder.Descending
   )
   ```

1. Check the formula bar and the left tree view for a blue underline or a warning triangle,
   which is how Power Apps flags a delegation limit.

   > **Note:** You may not see one. Whether this filter delegates depends on the connector
   > version, so treat its absence as normal rather than as a sign you did something wrong.
   > The point below matters either way.

   > **Key insight:** A delegation warning means Power Apps cannot ask Business Central to do the filtering, so instead it downloads the first 500 records and filters them on the device. With Contoso's data that is invisible. With a real customer's 40,000 purchase orders, an approver would see a list that is confidently wrong, with no error message at all. Read the warning now: hover over the blue underline and note which function is not delegable. You are going to accept this limit deliberately, because the lab dataset is small, but on a real deployment the fix is to filter server-side in the API page rather than in the app.

1. Set the gallery's **Layout** in the Properties pane to **Title, subtitle, and body**.

1. Select the **Title1** label inside the gallery and set its **Text** property to:

   ```
   ThisItem.number & "  -  " & ThisItem.vendorName
   ```

1. Select the **Subtitle1** label and set its **Text** property to:

   ```
   "Project: " & ThisItem.projectCode & "   Dept: " & ThisItem.departmentCode
   ```

1. Select the **Body1** label and set its **Text** property to:

   ```
   Text(ThisItem.totalAmount, "[$-en-US]$#,##0.00")
   ```

1. Confirm the gallery now lists your purchase orders with the project code visible. If `projectCode` shows as blank for every row, you are connected to the standard API rather than your custom one. Go back to Task 1.

### Task 3: Load the Budget Data

1. Select **App** at the top of the tree view on the left.

1. In the property dropdown, select **OnStart**, and set it to:

   ```
   ClearCollect(colBudgets, projectBudgets)
   ```

1. Select the **App** node again, choose the ellipsis in the tree view, and select **Run OnStart** so the collection populates now rather than on next launch.

1. Select **Variables** from the left pane. The pane opens empty: select **Refresh** to
   populate it, then expand **Collections** and confirm `colBudgets` shows `Table: 1 rows`,
   holding your `INFRA-2026` record from Challenge 01.

   > **Key insight:** Collecting the budgets once at startup rather than looking them up per row is a deliberate performance decision. Budgets change rarely and there are few of them, so one call at launch beats one call per gallery row on every scroll. The trade-off is staleness: if someone edits a budget while the app is open, the app will not notice. That is an acceptable trade here and would not be if budgets changed by the minute.

### Task 4: Add the Colour-Coded Budget Indicator

1. Select the gallery, then **Insert**, then **Rectangle** from the **Shapes** menu. It is added inside the gallery template, so it repeats on every row.

1. Rename it to `rectBudgetBar`.

1. Set its **Width** property to:

   ```
   200
   ```

1. Set its **Height** property to:

   ```
   12
   ```

1. Position it on the right side of the gallery row by dragging, or by setting **X** to `500` and **Y** to `30`.

1. Set its **Fill** property to the following. This looks up the budget for the row's project and colours the bar by how much is committed:

   ```
   With(
       {
           pct: If(
               IsBlank(LookUp(colBudgets, projectCode = ThisItem.projectCode && departmentCode = ThisItem.departmentCode)) || LookUp(colBudgets, projectCode = ThisItem.projectCode && departmentCode = ThisItem.departmentCode).budgetAmount = 0,
               0,
               LookUp(colBudgets, projectCode = ThisItem.projectCode && departmentCode = ThisItem.departmentCode).spentAmount / LookUp(colBudgets, projectCode = ThisItem.projectCode && departmentCode = ThisItem.departmentCode).budgetAmount
           )
       },
       Switch(
           true,
           pct > 0.9, Color.Firebrick,
           pct > 0.7, Color.Orange,
           Color.SeaGreen
       )
   )
   ```

   > **Important:** Repeat the whole `LookUp` each time rather than binding it once with
   > `With({b: LookUp(...)}, ...)`. Binding the looked-up **record** to a variable and then
   > reading `b.spentAmount` inside a gallery returns zero, even though the same `LookUp`
   > returns the correct values when read directly. It is verbose, and it is the difference
   > between a working indicator and one that silently reports zero.

1. With the gallery still selected, insert a **Label** into the gallery template and rename it to `lblBudgetPct`.

1. Set its **Text** property to:

   ```
   If(
       IsBlank(LookUp(colBudgets, projectCode = ThisItem.projectCode && departmentCode = ThisItem.departmentCode)) || LookUp(colBudgets, projectCode = ThisItem.projectCode && departmentCode = ThisItem.departmentCode).budgetAmount = 0,
       "No budget set",
       Text(
           Round(LookUp(colBudgets, projectCode = ThisItem.projectCode && departmentCode = ThisItem.departmentCode).spentAmount / LookUp(colBudgets, projectCode = ThisItem.projectCode && departmentCode = ThisItem.departmentCode).budgetAmount * 100, 0)
       ) & "% of budget committed"
   )
   ```

   > **Important:** Two things here are deliberate and both matter.
   >
   > The `LookUp` is repeated rather than bound with `With({b: ...})`, for the reason given
   > above.
   >
   > The percentage is calculated with `* 100` and `Round` rather than the `"0%"` format
   > string. `Text(value, "0%")` renders `0%` here regardless of the value passed to it, so
   > the multiplication is done explicitly and the `%` sign appended as text.

1. Position the label just below the rectangle.

1. Confirm that rows charged to `INFRA-2026` show **16% of budget committed** and a coloured
   bar, and that rows with no project code show **No budget set**.

   > **Note:** With a budget of 50,000 and committed spend of 8,023.24 the figure is 16%. If
   > you see **0%** on rows that clearly have a budget, a `With({b: LookUp(...)})` binding or
   > a `"0%"` format string has crept back into one of the two formulas above.

   > **Note:** The `IsBlank(b) || b.budgetAmount = 0` guard is doing real work. Without it, any purchase order charged to a project that has no budget record would divide by zero, and Power Apps would show a blank bar with no explanation. Handling the missing case explicitly is the difference between an app that looks broken and one that tells the user what is wrong.

### Task 5: Build the Details Pane

1. Select the gallery and set its **OnSelect** property to:

   ```
   Set(varSelectedPO, ThisItem)
   ```

1. Select **Insert**, then **Text label**, and place it to the right of the gallery, outside the gallery template.

   > **Important:** Watch the tree view as you insert. If the new label appears indented underneath `galPurchaseOrders`, it went inside the gallery and will repeat on every row. Select the screen first, then insert, to place it outside.

1. Rename it to `lblDetailHeader` and set its **Text** property to:

   ```
   If(
       IsBlank(varSelectedPO),
       "Select a purchase order",
       varSelectedPO.number & " - " & varSelectedPO.vendorName
   )
   ```

1. Insert a second label named `lblDetailBudget` beneath it, and set its **Text** property to:

   ```
   If(
       IsBlank(varSelectedPO),
       "",
       With(
           {b: LookUp(colBudgets, projectCode = varSelectedPO.projectCode && departmentCode = varSelectedPO.departmentCode)},
           If(
               IsBlank(b),
               "No budget record exists for project " & varSelectedPO.projectCode,
               "Budget: " & Text(b.budgetAmount, "[$-en-US]$#,##0") &
               "   Committed: " & Text(b.spentAmount, "[$-en-US]$#,##0") &
               "   Remaining: " & Text(b.remainingAmount, "[$-en-US]$#,##0") &
               Char(10) &
               "If rejected, remaining would be " &
               Text(b.remainingAmount + varSelectedPO.totalAmount, "[$-en-US]$#,##0")
           )
       )
   )
   ```

1. Set the label's **AutoHeight** property to `true` and its **Size** to `14` so the multi-line text is readable.

   > **Important - the projection adds, it does not subtract.** The obvious formula is
   > `remainingAmount - totalAmount`, on the reasoning that approving an order consumes budget.
   > It is wrong, and it produces confident nonsense: a $31,361 order against a $10,616
   > remaining balance reports *"If approved, remaining would be -$20,745"*.
   >
   > The reason is that `Spent Amount` counts **every** purchase order of type Order, whether
   > approved or not. The order in front of the approver is already inside the committed
   > figure, so subtracting it again double-counts. Approving it changes nothing financially -
   > the commitment was made when the order was raised. What changes the numbers is a
   > **rejection**, which returns the money to the budget.
   >
   > This is worth pausing on, because the wrong version looks right for as long as your test
   > data was created before your budget record. That is the same class of error as the stale
   > `Spent Amount` in Challenge 01: a figure that is only correct by coincidence, displayed
   > with total confidence, and wrong the moment anyone does something new.

### Task 6: Add the Approve and Reject Buttons

1. Select the screen, then **Insert**, then **Button**. Place it below the details pane.

1. Rename it to `btnApprove` and set its **Text** property to `"Approve"`.

1. Set its **DisplayMode** property to:

   ```
   If(IsBlank(varSelectedPO), DisplayMode.Disabled, DisplayMode.Edit)
   ```

1. Set its **OnSelect** property to the following placeholder. You will replace this in Challenge 03:

   ```
   Notify("Approval flow not yet connected - Challenge 03", NotificationType.Warning)
   ```

1. Insert a second button named `btnReject` with **Text** set to `"Reject"`, the same **DisplayMode** formula, and this **OnSelect**:

   ```
   Notify("Rejection flow not yet connected - Challenge 03", NotificationType.Warning)
   ```

### Task 7: Test and Save

1. Press **F5** to open Preview mode.

1. Confirm each of the following:

   - The gallery lists purchase orders with vendor, amount and project code
   - Rows charged to `INFRA-2026` show a coloured bar and a committed percentage
   - Selecting a row updates the details pane on the right
   - The details pane shows what the remaining budget would be after approval
   - The Approve and Reject buttons are disabled until a row is selected

1. Close Preview with **Esc**.

1. Select **Save** from the top-right corner, then **Publish**, then **Publish this version**.

   > **Note:** Publish rather than only saving. Challenge 05 packages the published version, and an unpublished draft will not carry your latest work into the managed solution.

## Success Criteria

- [ ] A canvas app named `Purchase Approval Hub <inject key="DeploymentID" enableCopy="false"></inject>` exists in your own environment
- [ ] The app is connected to `purchaseOrders` and `projectBudgets` from the **contoso / procurement** API group, not the standard v2.0 group
- [ ] The gallery displays PO number, vendor, amount and project code from live Business Central data
- [ ] The budget bar renders green, amber or red according to committed percentage, and rows with no budget show **No budget set**
- [ ] Selecting a row populates a details pane showing budget, committed, remaining, and remaining after approval
- [ ] Approve and Reject buttons exist and are disabled when nothing is selected
- [ ] The app is published
- [ ] You can state which formula raised the delegation warning and what would go wrong at 40,000 records

## Additional Resources

- [Dynamics 365 Business Central connector](https://learn.microsoft.com/en-us/connectors/dynamicssmbsaas/)
- [Understand delegation in canvas apps](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/delegation-overview)
- [Gallery control](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/controls/control-gallery)
- [With function](https://learn.microsoft.com/en-us/power-platform/power-fx/reference/function-with)

Now, click **Next** to continue to **Challenge 03**.
