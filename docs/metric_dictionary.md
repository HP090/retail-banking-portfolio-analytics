# Retail Banking Portfolio Intelligence: Metric Dictionary

## 1. Purpose

This document defines the business meaning and analytical use of the project’s metrics and flags.

It begins with the two transaction-level flags required for account engagement and external credit-inflow analysis. Additional portfolio, cohort, relationship and loan metrics will be added as their SQL marts are developed.

The executable raw-code mappings will be stored in `conf/source_codes.yaml`. This document explains the business definitions; the configuration file will become the technical source of truth.

---

## 2. Transaction fields used

The two flags are derived from the following transaction fields:

* `direction`: whether the transaction credits or debits the account.
* `operation`: how the transaction was performed.
* `purpose`: the reported reason or category of the transaction.
* `amount`: the positive monetary value of the transaction.

The exact raw values must be confirmed during the source audit because dataset versions may use either the original Czech codes or translated values.

Every distinct non-missing code must be mapped. An unexpected code must be reported as a data-quality exception rather than silently guessed.

---

## 3. Qualifying account activity

### Metric name

`is_qualifying_account_activity`

### Grain

One transaction.

### Data type

Boolean:

* `TRUE`: the transaction provides evidence that the account is being used.
* `FALSE`: the transaction is bank-generated, administrative or otherwise excluded from the activity definition.

### Business definition

Qualifying account activity identifies transactions that provide evidence of account use or engagement.

The purpose is to distinguish meaningful account activity from transactions that can occur automatically even when the account holder is not actively using the account.

For example, an inactive account may continue receiving interest credits or statement-fee deductions. Counting these entries as activity would make the account appear active even when it has recorded no meaningful account use.

### Expected qualifying operations

Subject to confirmation against the selected source version, the following operations count as qualifying account activity:

| Standardised operation | Original code    | Qualifying activity | Reason                                              |
| ---------------------- | ---------------- | ------------------: | --------------------------------------------------- |
| Cash deposit           | `VKLAD`          |                TRUE | Money is actively deposited into the account        |
| Incoming transfer      | `PREVOD Z UCTU`  |                TRUE | The account is being used to receive external funds |
| Cash withdrawal        | `VYBER`          |                TRUE | The account is used to withdraw cash                |
| Card withdrawal        | `VYBER KARTOU`   |                TRUE | The account is used through an issued card          |
| Outgoing transfer      | `PREVOD NA UCET` |                TRUE | The account is used to make a payment or transfer   |

An incoming transfer may count as account activity, but it must not automatically be described as a transaction personally initiated by the account owner.

### Excluded purposes

Subject to confirmation during the source audit, the following bank-generated or administrative purposes do not count as qualifying account activity:

| Standardised purpose     | Original code | Qualifying activity | Reason                                                   |
| ------------------------ | ------------- | ------------------: | -------------------------------------------------------- |
| Interest credited        | `UROK`        |               FALSE | The bank generates the entry automatically               |
| Statement or service fee | `SLUZBY`      |               FALSE | Administrative bank charge                               |
| Sanction interest        | `SANKC. UROK` |               FALSE | Bank-generated charge associated with a negative balance |

Other recognised purposes, such as household payments, insurance payments and loan payments, may count as qualifying activity when they are attached to a recognised qualifying operation.

### Conceptual rule

A transaction qualifies when:

1. Its operation belongs to the approved qualifying-operation list.
2. Its purpose is not classified as interest, a bank fee or another excluded administrative entry.
3. Its source codes have been successfully mapped.

### Uses

This flag will be used to calculate:

* Active accounts.
* Account first-activity month.
* First-activity cohort retention.
* RFM-style recency.
* RFM-style frequency.
* Dormant and lapsed account conditions.
* Qualifying transaction counts.

### Limitations

* It measures observable account use, not a person’s intentions.
* An incoming transfer may be passive rather than personally initiated.
* It does not prove that an account holder logged in or consciously interacted with the bank.
* It must not be called customer-initiated activity unless the operation code supports that claim.

---

## 4. External credit inflow

### Metric name

`is_external_credit_inflow`

### Grain

One transaction.

### Data type

Boolean:

* `TRUE`: the transaction represents an eligible credit entering the account from outside the bank’s own interest or administrative postings.
* `FALSE`: the transaction is a debit, internal bank-generated credit or excluded administrative entry.

### Business definition

External credit inflow identifies eligible money credited to an account from outside the bank’s own interest and administrative postings.

Examples may include:

* Cash deposits.
* Incoming account transfers.
* Pension receipts.
* Other recognised incoming external payments.

The purpose is to separate genuinely incoming account cash from interest that the bank itself credits to an account.

### Expected inclusion rule

Subject to source-audit confirmation, a transaction is an external credit inflow when:

1. The standardised direction is `credit`.
2. The amount is positive.
3. The operation is an eligible cash deposit or incoming transfer.
4. The purpose is not interest or another excluded administrative entry.
5. Every relevant source code has been successfully mapped.

Expected qualifying operations include:

| Standardised operation | Original code   | External credit inflow | Reason                                                       |
| ---------------------- | --------------- | ---------------------: | ------------------------------------------------------------ |
| Cash deposit           | `VKLAD`         |                   TRUE | Cash enters the account from outside the bank’s own postings |
| Incoming transfer      | `PREVOD Z UCTU` |                   TRUE | Funds arrive from another account or bank                    |

A pension purpose such as `DUCHOD` is included when it appears as an eligible incoming transfer.

### Expected exclusions

| Transaction type         | Example code or condition | External credit inflow | Reason                                                    |
| ------------------------ | ------------------------- | ---------------------: | --------------------------------------------------------- |
| Interest credited        | `UROK`                    |                  FALSE | This is the bank crediting its own interest expense       |
| Statement or service fee | `SLUZBY`                  |                  FALSE | This is an administrative debit rather than incoming cash |
| Sanction interest        | `SANKC. UROK`             |                  FALSE | This is a bank-generated charge                           |
| Cash withdrawal          | `VYBER`                   |                  FALSE | Money leaves the account                                  |
| Card withdrawal          | `VYBER KARTOU`            |                  FALSE | Money leaves the account                                  |
| Outgoing transfer        | `PREVOD NA UCET`          |                  FALSE | Money leaves the account                                  |
| Non-positive amount      | `amount <= 0`             |                  FALSE | It does not represent positive incoming cash              |
| Unmapped source code     | Any unexpected code       |  Not silently assigned | The code must be investigated                             |

If a reversal or other administrative credit can be identified from the source codes, it must also be excluded. A reversal must not be invented where the dataset provides no identifiable reversal code.

### Uses

This flag will be used to calculate:

* Monthly external credit inflows by account.
* Aggregate portfolio external credit inflows.
* Pre-origination average account inflows.
* Payment-to-inflow ratios.
* Relationship-segment inflow summaries.
* The next-month aggregate external credit-inflow forecast.

### Limitations

External credit inflow is not equivalent to:

* Bank revenue.
* Bank profit.
* Customer salary or income.
* Net cash flow.
* Total positive account balances.
* The bank’s complete liquidity position.

It measures one component of account cash movement. Debits, internal funding requirements and other assets and liabilities are outside this metric.

---

## 5. Difference between the two flags

The two flags answer different questions.

| Flag                             | Question answered                                  | Example                                     |
| -------------------------------- | -------------------------------------------------- | ------------------------------------------- |
| `is_qualifying_account_activity` | Is there evidence that this account is being used? | A cash withdrawal or outgoing bill payment  |
| `is_external_credit_inflow`      | Is eligible external money entering this account?  | A cash deposit or incoming pension transfer |

A transaction can satisfy both flags.

For example, a cash deposit can be:

* Qualifying account activity because it demonstrates account use.
* External credit inflow because money enters the account.

A cash withdrawal is:

* Qualifying account activity.
* Not external credit inflow.

An interest credit is:

* Not qualifying account activity.
* Not external credit inflow.

---

## 6. Required validation

Before the flags are used in any mart:

* List every distinct transaction direction.
* List every distinct operation.
* List every distinct purpose.
* Record SQL NULLs, blank values and coded missing values.
* Map every recognised code in `conf/source_codes.yaml`.
* Investigate every unexpected code.
* Confirm that external-inflow rows have credit direction and positive amounts.
* Confirm that excluded interest and fee rows never receive a qualifying flag.
* Reconcile flagged transaction counts and amounts against source totals.
* Document any dataset-version differences.

These validations will be implemented during ingestion and staging.
