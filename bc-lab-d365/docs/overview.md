# Extending Business Central with Power Platform, AL and Copilot Studio

Contoso Manufacturing's Business Central deployment has outgrown its standard purchase approval workflow. Finance needs project-level spend tracking with budget versus actual visibility on every purchase order. The procurement team wants a mobile-friendly approval interface that shows budget context next to the PO details. Auditors need a complete approval trail. And the CFO wants a budget advisory agent so approvers can ask "what will this PO do to the project budget?" before they click Approve.

None of that exists today. Business Central has no project spend field on the Purchase Order, so budget tracking happens in a spreadsheet that is reconciled monthly and is wrong for most of the month. Approvers see an amount and a vendor, and nothing about whether the project can afford it.

In this Hack in a Day you will close that gap using every layer of the Microsoft stack: AL to extend Business Central itself, a custom API page to expose your new data, Power Apps for the approval interface, Power Automate for multi-level routing, and Copilot Studio for the budget advisor. You finish by packaging the whole thing as a managed solution and validating it in a second environment, the way a real deployment works.

## The Scenario

Contoso Manufacturing runs more than 40 capital and operational projects at once. Every purchase should be tagged to a project and a budget category, but the current Business Central setup has nowhere to put that information. Finance has mandated that the next fiscal year opens with full project spend tracking inside Business Central and a modern approval experience on top of it. You are the developer assigned to deliver it.

## What You Will Build

| Component | What It Does |
|---|---|
| **AL extension** | Adds Project Code, Department and Budget Category to the Purchase Order, plus a Project Budget table with live spend calculation |
| **Custom API page** | Exposes your new fields and the Project Budget table to Power Platform, which the standard Business Central API does not do |
| **Purchase Approval Hub** | Power Apps canvas app listing pending POs with colour-coded budget gauges |
| **Multi-level approval flow** | Power Automate routes by PO amount through one, two or three approval tiers with Teams approval cards |
| **Spend Advisor agent** | Copilot Studio agent published to Teams, answering budget impact questions against live Business Central data |
| **Managed solution** | Everything packaged and promoted to a second environment, with a documented deployment sequence |

## Solution Architecture

The AL extension is the foundation. It adds the project tracking fields to the Purchase Header table, creates a Project Budget table with a spend calculation codeunit, and publishes both through a custom API page. That API page matters more than it sounds: the standard Business Central `purchaseOrders` API does not return fields added by your extension, so without it the rest of the lab has nothing to read.

Power Apps reads purchase orders and budgets through that API using the Dynamics 365 Business Central connector. When an approver acts, a Power Automate flow routes the request through the correct number of approval tiers, updates the purchase order back in Business Central, and writes an audit record to Dataverse. The Copilot Studio agent calls the same API through its own flows, so every surface reads one source of truth.

## Key Tools and Services

- **Dynamics 365 Business Central** - the ERP being extended
- **AL and Visual Studio Code** - Business Central extension development
- **Power Apps** - the canvas approval interface
- **Power Automate** - multi-tier approval routing and the agent's data actions
- **Copilot Studio** - the Spend Advisor agent
- **Microsoft Dataverse** - the approval audit log
- **Microsoft Teams** - approval cards and the agent's channel

## Learning Objectives

By the end of this Hack in a Day you will be able to:

- Write AL table extensions and page extensions to add custom fields to Business Central
- Build a custom API page and explain why extension fields are invisible without one
- Connect a Power Apps canvas app to Business Central and handle delegation limits
- Build a multi-tier approval flow with Teams approvals and a Dataverse audit trail
- Create a Copilot Studio agent that answers questions from live ERP data, and test that it refuses questions it should not answer
- Package Power Platform and AL components into a repeatable deployment

## Hack in a Day Format

Five challenges covering AL development, Power Platform and deployment. Level L300 Advanced. Estimated total time 3 hours 45 minutes. Some AL familiarity helps, but every code file you need is given to you in full.

## Support Contact

The CloudLabs support team is available 24/7, 365 days a year, via email and live chat to ensure seamless assistance at any time.

Learner Support Contacts:

- Email Support: cloudlabs-support@spektrasystems.com
- Live Chat Support: https://cloudlabs.ai/labs-support

Click **Next** at the bottom of the page to proceed to Getting Started.

## Happy Hacking!!
