# Challenge 04: Build the Spend Advisor Agent

## Introduction

The Purchase Approval Hub shows an approver the budget position for the purchase order in front of them. That answers one question. It does not answer the questions approvers actually ask before signing off on something large: what else is already committed against this project, which projects are running over, and how much room is left if I approve three of these this week.

Those questions do not fit on a screen, because you cannot predict them. They fit a conversation. In this challenge you will build the Spend Advisor, a Copilot Studio agent that answers budget questions from live Business Central data through the API you built in Challenge 01.

The agent will be published to Microsoft Teams, which is where your approvers already are. Challenge 03 sends them approval cards in Teams, so putting the advisor in the same place means an approver can read the card, ask the advisor a question, and decide, without ever changing application.

> **Important:** You may have seen guidance about embedding a Copilot Studio agent directly inside a canvas app using the Copilot control. Microsoft's documentation states that "Starting February 2, 2026, you can't add the Copilot control to new canvas apps", and the same date applies to adding a custom Copilot to new canvas apps. That route is closed for an app built today, which is why this challenge publishes to Teams instead. This is worth knowing beyond the lab: a design that depends on a preview control can be invalidated by a release note.

## Challenge Objectives

- Create a Copilot Studio agent with a scoped set of instructions
- Build Power Automate actions that query live Business Central data for the agent
- Author topics that answer three distinct budget questions
- Publish the agent to Microsoft Teams
- Verify the agent refuses a question it should not answer, which matters as much as the answers

## Duration

50 minutes

## Your Assignment

> The CFO asked for this agent after an approver signed off a purchase that took a project 40 percent over budget, having checked nothing, because checking meant opening three screens. The CFO also made one thing clear during the requirements call: the agent must never guess. If it does not have the data, it must say so. An advisor that invents a number is worse than no advisor, because people believe it.

## Steps to Complete

### Task 1: Build the Budget Lookup Action

The agent cannot query Business Central directly. It calls flows, which do the querying. You will build those flows first.

> **Important - build these flows inside Copilot Studio, not in Power Automate.** An agent can
> only attach a flow that belongs to it. A flow you create at `make.powerautomate.com`, even
> with the correct trigger, will not appear in the agent's action picker in Task 4, and there
> is no way to move it across afterwards. Both flows in this challenge are therefore created
> from the **Agent flows** area of Copilot Studio. They will still be visible in Power
> Automate afterwards, and you can edit them from either place.

1. Navigate to Copilot Studio and confirm the environment picker shows `ODL_User <inject key="DeploymentID" enableCopy="false"></inject>'s Environment`:

   ```
   https://copilotstudio.microsoft.com
   ```

1. In the left navigation pane, select **Flows**. If you do not see it, select **...** (More) to find it. The page is titled **Agent flows**.

1. Select **+ New agent flow**.

1. Name it exactly:

   ```
   Get Project Budget <inject key="DeploymentID" enableCopy="false"></inject>
   ```

   > **Note:** Rename the flow using the title at the top left of the designer. A new agent
   > flow opens with a generated name, so do this before you build anything, otherwise it is
   > easy to forget and end up unable to identify the flow in Task 4.

1. The flow opens with the **When an agent calls the flow** trigger already in place. You do
   not need to add it.

   > **Note:** Older documentation calls this trigger **When an agent calls the skill**, and
   > some environments label it **Run a flow from Copilot**. All three names refer to the same
   > trigger.

1. On the trigger, select **+ Add an input**, choose **Text**, and name it:

   ```
   ProjectCode
   ```

1. Select **+ New step**, search for `Business Central`, and select **Find records (V3)**.

   > **Note:** The action is named **Find records (V3)**, not *List records*. Some older
   > documentation and screenshots still show the latter. If you add the wrong one, or rename
   > the action after adding it, the expressions later in this task will not resolve and the
   > flow refuses to save with *"The template validation failed: ... contains an invalid
   > reference to 'List_records_(V3)'"*. Leave the action's default name alone - the
   > expressions below depend on it being exactly `Find_records_(V3)`.

1. Configure it:

   - **Environment:** the Business Central environment name you noted in Getting Started
   - **Company:** the Business Central company name you noted in Getting Started
   - **Table:** `projectBudgets` from the **contoso / procurement** group

1. Expand **Advanced parameters** and set **Filter Query** to the following, using the dynamic content picker for the `ProjectCode` value:

   ```
   projectCode eq '<ProjectCode>'
   ```

1. Select **+ New step**, search for `Condition`, and add one named `Budget found`.

1. Configure the condition using the **Expression** tab:

   - Left: `length(outputs('Find_records_(V3)')?['body/value'])`
   - Operator: **is greater than**
   - Right: `0`

1. In the **If yes** branch, add a **Respond to the agent** action with these outputs:

   | Name | Type | Value |
   |---|---|---|
   | `Found` | Text | `Yes` |
   | `BudgetAmount` | Number | `first(outputs('Find_records_(V3)')?['body/value'])?['budgetAmount']` |
   | `SpentAmount` | Number | `first(outputs('Find_records_(V3)')?['body/value'])?['spentAmount']` |
   | `RemainingAmount` | Number | `first(outputs('Find_records_(V3)')?['body/value'])?['remainingAmount']` |

1. In the **If no** branch, add a second **Respond to the agent** action with the same four outputs, setting `Found` to `No` and the three numbers to `0`.

   > **Key insight:** The `Found` flag is what stops the agent inventing an answer. Without it, a query for a project that does not exist returns three zeros, and the agent will cheerfully report that the project has a budget of zero and nothing remaining. That is a plausible sentence and a false statement. Returning an explicit `No` gives the topic something unambiguous to branch on, which is how you make "I do not have that data" a designed response rather than an accident.

1. Select **Publish**.

   > **Important:** Publish, not **Save draft**. An agent flow that has only been saved as a
   > draft does not appear to the agent, and the failure in Task 4 looks identical to the flow
   > not existing at all. Wait for the confirmation banner reading *"Your agent flow was
   > published"* before moving on.

### Task 2: Build the Committed Purchase Orders Action

1. Return to **Flows** in Copilot Studio and select **+ New agent flow** again. Name this one
   exactly:

   ```
   List POs by Project <inject key="DeploymentID" enableCopy="false"></inject>
   ```

   > **Important:** Create this one in Copilot Studio as well, for the same reason as Task 1,
   > and rename it straight away using the title at the top left of the designer. It opens as
   > **Untitled**, and two flows called Untitled are indistinguishable in Task 4's action
   > picker.

1. It opens with the same **When an agent calls the flow** trigger. Add one **Text** input named `ProjectCode`.

1. Add a Business Central **Find records (V3)** action configured against the `purchaseOrders` table from your **contoso / procurement** group, with a **Filter Query** of:

   ```
   projectCode eq '<ProjectCode>'
   ```

1. Select **+ New step**, search for `Select`, and add the **Data Operation - Select** action.

1. Set **From** to the `value` output of the Find records action.

1. Leave the **Map**'s **key** box completely empty, and set the **value** box to:

   ```
   concat(item()?['number'], ' - ', item()?['vendorName'], ' - ', formatNumber(item()?['totalAmount'], 'C0', 'en-US'))
   ```

   > **Important - the empty key is deliberate, and the text-mode toggle is a trap.** With no
   > key, **Select** returns a flat array of strings, which is what `join()` needs in the next
   > step. Give the key a name and you get an array of objects instead, and `OrderList` comes
   > back as unreadable JSON.
   >
   > The icon to the right of the Map switches to text mode. Do not use it here. In the agent
   > flow designer that box is validated as JSON, so pasting the expression into it produces
   > **Invalid parameters** and *"Enter a valid JSON"*. Older documentation shows the
   > expression pasted into text mode, which worked in the classic designer.

1. Add a **Respond to the agent** action with these outputs:

   | Name | Type | Value |
   |---|---|---|
   | `OrderCount` | Number | `length(outputs('Find_records_(V3)')?['body/value'])` |
   | `OrderList` | Text | see the expression below |

   For `OrderList`, use the expression editor and enter:

   ```
   replace(replace(replace(join(body('Select'), '|'), '{"":"', ''), '"}', ''), '|', decodeUriComponent('%0A%0A'))
   ```

   > **Why this is not just a `join`.** The obvious expression,
   > `join(body('Select'), decodeUriComponent('%0A'))`, does not work. Even with an empty key,
   > **Select** returns an array of *objects* rather than an array of strings, and `join`
   > serialises each one, so the agent replies with:
   >
   > ```
   > {"":"106001 - Fabrikam, Inc. - $5,793"} {"":"106002 - First Up Consultants - $2,230"}
   > ```
   >
   > The three nested `replace` calls join with a separator, strip the `{"":"` and `"}`
   > wrappers the serialiser adds, then turn the separator into a blank line. The blank line
   > matters: Copilot Studio renders agent messages as markdown, and a single newline collapses
   > so both orders appear on one line.

   > **Note:** A cleaner-looking alternative is to drop **Select** and build the string with
   > **Initialize variable**, **Apply to each** and **Append to string variable**. It was tried
   > and rejected during testing: the agent flow designer repeatedly discarded the
   > **Initialize variable** action's configuration, blanking its Name and resetting its Type,
   > which then left **Append to string variable** with an empty and unselectable Name
   > dropdown. The expression above uses only actions that behave predictably here.

1. Select **Publish**.

   > **Important:** Publish, not **Save draft**. An agent flow that has only been saved as a
   > draft does not appear to the agent, and the failure in Task 4 looks identical to the flow
   > not existing at all. Wait for the confirmation banner reading *"Your agent flow was
   > published"* before moving on.

### Task 3: Create the Agent

1. Navigate to Copilot Studio:

   ```
   https://copilotstudio.microsoft.com
   ```

1. Confirm the environment picker shows `ODL_User <inject key="DeploymentID" enableCopy="false"></inject>'s Environment`.

1. Select **Create** from the left navigation pane, then **New agent**.

1. If offered a conversational setup, select **Skip to configure** so you can set the fields directly.

1. Set the name exactly:

   ```
   Spend Advisor <inject key="DeploymentID" enableCopy="false"></inject>
   ```

1. Set the **Description** to:

   ```
   Answers budget and committed spend questions for Contoso Manufacturing purchase approvers, using live Business Central data.
   ```

1. Set the **Instructions** to the following:

   ```
   You are a budget advisor for purchase approvers at Contoso Manufacturing.

   You only answer questions about project budgets, committed purchase order
   spend, and the budget impact of approving a purchase order.

   Every number you give must come from an action result in the current
   conversation. Never estimate, never calculate from memory, and never carry a
   figure over from an earlier conversation.

   If an action reports that it found no data, say plainly that you have no
   budget record for that project and suggest the approver contact Finance. Do
   not offer a figure of zero as though it were a real budget.

   If asked about anything other than project budgets and purchase order spend,
   decline and say you can only help with budget questions for purchase
   approvals.
   ```

1. Select **Create**.

1. Once the agent opens, confirm the **Instructions** actually saved. Select the agent's
   **Overview** tab and look at the **Instructions** field.

   > **Important:** Depending on which creation path Copilot Studio puts you through, the
   > agent can be created with an **empty** Instructions field even though you filled it in.
   > The newer conversational setup in particular may skip it. If it is empty, paste the
   > instructions above into it now and select **Save**.
   >
   > An agent with no instructions still works, which is the problem. It answers budget
   > questions plausibly and confidently, and it will happily answer questions about anything
   > else too. Task 7 asks you to prove it refuses an off-topic question, and that test fails
   > for a reason that is nowhere near the topic you will be looking at.

   > **Key insight:** Read the third paragraph of those instructions again. It is doing the work the CFO asked for. Large language models are fluent by default and will produce a confident sentence whether or not the data supports it. Constraining the agent to figures that appear in the current conversation's action results is the difference between a tool Finance can rely on and one that quietly manufactures numbers.

### Task 4: Build the Remaining Budget Topic

1. In your agent, select **Topics** from the top menu, then **+ Add a topic**, then **From blank**.

   > **Important - do not describe the topic and let Copilot Studio build it.** The topic
   > designer offers a **Describe what the topic does** box, and the trigger may default to
   > **The agent chooses**. Taking that route produces a complete, plausible-looking topic
   > that calls no action at all and answers from hardcoded sample data instead:
   >
   > ```
   > condition: =Topic.ProjectCode = "ABC123"
   >   activity: |-
   >     - Budget amount: $100,000
   >     - Committed amount: $60,000
   > ```
   >
   > Those project codes and figures do not exist anywhere in your Business Central data. The
   > agent will report them confidently, and will tell you it has no record for `INFRA-2026`,
   > which does exist. It is worth pausing on this: the generated topic is not broken, it is
   > fluent and wrong, and it is the precise behaviour the CFO in this scenario said was worse
   > than having no advisor at all. Build the topic by hand.

1. Rename the topic to `Remaining Budget`.

1. Select the **Trigger** node and add these phrases:

   ```
   What is the remaining budget
   How much is left on this project
   Budget available for a project
   How much can I still spend
   Show me the budget position
   ```

1. Select **+** below the trigger, then **Ask a question**.

   - **Question:** `Which project code are you asking about?`
   - **Identify:** `User's entire response`
   - **Save response as:** `ProjectCode`

1. Select **+**, then **Add a tool**, then choose `Get Project Budget <inject key="DeploymentID" enableCopy="false"></inject>` from the list.

   > **Note:** Older documentation describes this as **Call an action** followed by **Run a
   > flow from Copilot**. In the current designer the flows are listed directly under
   > **Add a tool**, below the built-in entries such as **New Agent flow** and **New prompt**.
   > If your flow is not in that list, it was created in Power Automate rather than in Copilot
   > Studio, and it will have to be rebuilt. See the warning at the start of Task 1.

1. Map the flow's `ProjectCode` input to the `ProjectCode` variable.

1. Select **+**, then **Add a condition**.

   - Set the condition to check whether the flow's `Found` output **is equal to** `Yes`.

1. In the **If yes** branch, select **+**, then **Send a message**, and enter the following, inserting the flow output variables where shown:

   ```
   Project {Topic.ProjectCode}: budget {Topic.BudgetAmount}, committed {Topic.SpentAmount}, remaining {Topic.RemainingAmount}.
   ```

   > **Important - the `Topic.` prefix is required.** Insert each variable with the **{x}**
   > button in the message toolbar rather than typing the name. Referring to a variable by its
   > bare name gives *"Identifier not recognized in expression 'ProjectCode'"*, because topic
   > variables are scoped and the designer's own Variables panel lists them as
   > `Topic.ProjectCode`, `Topic.BudgetAmount` and so on.

1. In the **All other conditions** branch, add a **Send a message** node with:

   ```
   I have no budget record for project {Topic.ProjectCode}. Please check the project code, or contact Finance to have a budget created.
   ```

1. Select **Save**.

### Task 5: Build the Committed Spend Topic

1. Add a second topic named `Committed Purchase Orders`.

1. Add these trigger phrases:

   ```
   What is committed against this project
   Show me the POs for a project
   Which purchase orders are charged to this project
   List open orders for a project
   ```

1. Add an **Ask a question** node identical to the one in Task 4, saving the response as `ProjectCode`.

1. Select **+**, then **Add a tool**, and choose `List POs by Project <inject key="DeploymentID" enableCopy="false"></inject>`, mapping the `ProjectCode` variable.

1. Add a **condition** checking whether `OrderCount` **is greater than** `0`.

1. In the **If yes** branch, add a **Send a message** node with:

   ```
   There are {Topic.OrderCount} purchase orders charged to {Topic.ProjectCode}:

   {Topic.OrderList}
   ```

1. In the **All other conditions** branch, add a **Send a message** node with:

   ```
   No purchase orders are currently charged to {Topic.ProjectCode}.
   ```

1. Select **Save**.

### Task 6: Constrain the Fallback

1. Select **Topics**, then open the **System** tab, and open the **Fallback** topic.

1. Find the message node that responds when the agent does not understand, and replace its text with:

   ```
   I can only help with project budgets and purchase order spend for Contoso approvals. For anything else, please contact the relevant team.
   ```

1. Select **Save**.

### Task 7: Test the Agent, Including What It Should Refuse

1. Open the **Test your agent** pane on the right of the Copilot Studio window.

1. Ask the following and confirm the agent returns live figures matching what you saw in Business Central in Challenge 01:

   ```
   What is the remaining budget for INFRA-2026?
   ```

1. Ask the following and confirm it lists the purchase orders you tagged in earlier challenges:

   ```
   What is committed against INFRA-2026?
   ```

1. Now run the negative tests. These must **fail to answer** in order to pass.

1. Ask about a project that does not exist:

   ```
   What is the remaining budget for FAKE-9999?
   ```

   Confirm the agent says it has no budget record and suggests contacting Finance. If instead it reports a budget of zero, your `Found` flag is not wired correctly. Return to Task 1.

1. Ask something outside its scope:

   ```
   What is Contoso's expenses policy for international travel?
   ```

   Confirm the agent declines and points you elsewhere. If it attempts an answer, tighten the **Instructions** in Task 3 and test again.

   > **Key insight:** These two tests are the real deliverable of this challenge. Any agent can be made to produce an answer. Building one that reliably declines when it should is harder, and it is the only reason Finance would ever trust a number it gives them. When you demonstrate this agent to a customer, show them the refusal before you show them the answer.

### Task 8: Publish to Microsoft Teams

1. Select **Publish** from the top of the Copilot Studio window, then confirm **Publish** in the dialog. Wait for the confirmation that publishing succeeded.

   > **Note:** Publishing requires a Copilot Studio user licence, which is already assigned to your lab account. If publish is unavailable, contact CloudLabs support rather than continuing.

1. Select **Channels** from the top menu.

1. Select **Microsoft Teams**, then **+ Add channel**.

1. Select **Turn on Teams** and wait for it to complete.

1. Select **See agent in Teams**. Teams opens with your agent ready to install.

1. Select **Add** to install the agent for yourself.

1. In the Teams chat with the agent, ask:

   ```
   What is the remaining budget for INFRA-2026?
   ```

1. Confirm the agent returns the same live figures it returned in the Copilot Studio test pane.

   > **Note:** If the agent responds in Teams but returns no data, the most common cause is that the flow connections were created under a different account than the one Teams is authenticated with. Open each flow in Power Automate and confirm the Business Central connection is valid.

## Success Criteria

- [ ] Two flows exist, `Get Project Budget <inject key="DeploymentID" enableCopy="false"></inject>` and `List POs by Project <inject key="DeploymentID" enableCopy="false"></inject>`, both using the agent trigger
- [ ] The budget flow returns an explicit `Found` value of `Yes` or `No`
- [ ] An agent named `Spend Advisor <inject key="DeploymentID" enableCopy="false"></inject>` exists with scoped instructions
- [ ] The **Remaining Budget** topic returns live figures matching Business Central
- [ ] The **Committed Purchase Orders** topic lists the purchase orders you tagged in Challenge 01
- [ ] Asking about `FAKE-9999` produces a plain statement that no budget record exists, **not** a budget of zero
- [ ] Asking an out-of-scope question produces a refusal
- [ ] The agent is published and reachable in Microsoft Teams, returning the same figures as the test pane

## Additional Resources

- [Create and edit topics in Copilot Studio](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-create-edit-topics)
- [Call Power Automate flows from Copilot Studio](https://learn.microsoft.com/en-us/microsoft-copilot-studio/advanced-flow)
- [Add your agent to Microsoft Teams](https://learn.microsoft.com/en-us/microsoft-copilot-studio/publication-add-bot-to-microsoft-teams)
- [Write effective agent instructions](https://learn.microsoft.com/en-us/microsoft-copilot-studio/guidance/instructions)
- [Business Central API endpoints](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/api-reference/v2.0/endpoints-apis-for-dynamics)

Now, click **Next** to continue to **Challenge 05**.
