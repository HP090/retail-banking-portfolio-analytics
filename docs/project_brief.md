# Retail Banking Portfolio Intelligence: Project Brief

## 1. Project purpose

This project builds a SQL-to-Streamlit retail banking intelligence platform using the historical PKDD'99 Czech Financial Dataset.

The platform is designed to help retail-bank managers monitor:

* Positive account-balance growth and concentration.
* Account activity and retention.
* Relationship value and inactivity.
* Loan-portfolio composition and recorded repayment status.
* Transparent conditions that may justify manual account review.
* Expected aggregate external credit inflows for the next month.

The project is a historical portfolio-analysis exercise. It is not a live banking system, a profitability model, a customer-churn model or a loan-default prediction system.

All financial amounts are denominated in Czech koruna (CZK).

---

## 2. Business users

### 2.1 Head of Retail Banking

The Head of Retail Banking requires a portfolio-level view of account balances and cash movement.

The dashboard should help this user understand:

* Whether positive account balances are growing.
* Whether balance growth is broadly distributed or concentrated among a small number of accounts.
* How external credit inflows and ledger debits are changing over time.
* Whether overdrawn exposure is increasing.
* How many accounts are recording qualifying activity.
* The expected aggregate external credit inflow for the following month.

This user is primarily interested in overall portfolio direction rather than individual account behaviour.

### 2.2 Deposit and Relationship Manager

The Deposit and Relationship Manager requires an account-level relationship view.

The dashboard should help this user understand:

* Which account relationships are active.
* Which accounts hold high positive balances.
* Which high-value accounts have become dormant or lapsed.
* How activity differs across first-activity cohorts.
* Which accounts have experienced a material balance decline.
* Which accounts satisfy transparent conditions for manual review.

The purpose is to prioritise investigation and relationship management. The dashboard does not automatically determine how an account holder should be treated.

### 2.3 Credit-Portfolio Manager

The Credit-Portfolio Manager requires a portfolio view of the bank’s recorded loans.

The dashboard should help this user understand:

* The composition of loan statuses at the dataset endpoint.
* How many loans and how much original principal were issued in each vintage.
* Which vintages have the highest completed problem-loan rate.
* Which vintages have the highest active-loan debt rate.
* How recorded loan outcomes differ across pre-origination balance and inflow bands.
* Whether some active loans are recorded as currently in debt at the dataset endpoint.

The dashboard does not predict default, reconstruct historical loan-status changes or calculate current outstanding principal.

---

## 3. Primary analytical unit

The primary analytical unit is the bank account, identified by `account_id`.

This is necessary because the dataset records the following at account level:

* Transactions.
* Reported balances.
* Loans.
* Standing orders.
* Account activity.

The `disp` disposition table acts as a bridge between clients and accounts. An account can be connected to more than one client, such as an owner and an authorised user.

Therefore, joining the client and account tables without controlling the relationship could duplicate account-level values.

For example, suppose account 100 has a balance of CZK 50,000 and is connected to two clients. A direct client-to-account join would produce two rows containing the same CZK 50,000 balance. Summing those rows would incorrectly report CZK 100,000.

To prevent this:

* Every account balance must be counted once.
* Every account must appear once in account-level cohorts, segments and watchlists.
* The designated owner is used when one client record is required to describe an account.
* Authorised users remain represented in the customer-account bridge but do not create additional copies of account-level financial values.

---

## 4. Analytical terminology and rules

### 4.1 Account counts and client counts

Accounts and clients are different entities.

If a query counts 4,000 distinct account IDs, the result must be labelled as 4,000 accounts—not 4,000 customers.

Customer or client counts must be calculated separately using `client_id`.

### 4.2 Cohorts, segmentation and watchlists

The following are account-level outputs:

* First-activity cohorts.
* RFM-style relationship segments.
* Account-review watchlists.
* Balance-concentration measures.

They must not be duplicated across every client authorised to use an account.

### 4.3 Client demographic variables

Client demographic variables, such as age and gender, are descriptive only.

They must not be used to:

* Determine relationship segments.
* Set account-review rules.
* Recommend which accounts should receive different treatment.
* Infer loan eligibility.
* Explain or predict problem-loan status.

When one demographic record is required for an account-level descriptive output, use the designated owner and document that decision.

### 4.4 Positive account balances

The dataset contains one generic account relation rather than clearly separated savings, current-account and investment products.

For this reason, positive account balances are treated as a proxy for the bank’s positive account-balance or deposit base.

They must not be described as:

* A complete measure of customer deposits.
* A separate savings product.
* Assets under management.
* Bank revenue or profit.
* Current outstanding loan principal.

### 4.5 Loan status

The loan table contains one recorded status for each loan. It does not contain a history showing when that status changed.

Loan status must therefore be interpreted as the status observed at the dataset endpoint.

The project can compare:

* Completed satisfactory loans.
* Completed problem loans.
* Active satisfactory loans.
* Active loans recorded in debt.

The project cannot determine the exact historical date on which a loan first fell behind, recovered or changed status.

---

## 5. Business questions

Every SQL mart and dashboard chart must contribute to answering at least one of the following questions.

### Question 1: Are positive account balances growing, and is that growth broadly distributed?

A rise in total positive account balances may appear healthy while being driven by only a few very high-balance accounts.

The project will therefore examine both:

* Total positive account balances.
* The share of positive balances held by the top 10% of eligible accounts.

This distinguishes broad portfolio growth from concentration risk.

### Question 2: Which account first-activity cohorts continue to record qualifying activity?

Accounts will be grouped according to the first month in which they record qualifying account activity.

For example, if 100 accounts first record qualifying activity in January, cohort analysis measures how many of those same accounts record qualifying activity in February, March and later months.

This is account activity retention. It is not necessarily account-opening or customer-acquisition retention.

An account may become active again after an inactive month, so the measure is not continuous survival.

### Question 3: Which account relationships are active, valuable, dormant or deteriorating at the configured snapshot?

A relationship manager cannot investigate every account individually.

The project will create an RFM-style account segmentation using:

* Recency of qualifying activity.
* Frequency of active months.
* Average positive month-end balance.
* Recent balance movement.
* Product holdings.

This identifies groups such as core relationships, active developing accounts, high-value dormant accounts and low-engagement accounts.

The segments describe account relationships. They do not measure profitability or customer lifetime value.

### Question 4: Which loan vintages have the highest completed problem-loan rate or active-loan debt rate?

A loan vintage is the year in which a loan was originated.

The project will compare whether loans originated in one year recorded different outcomes from loans originated in another year.

Completed and active loans require separate rates:

* Completed problem-loan rate: problem completed loans divided by all completed loans.
* Active-loan debt rate: active loans in debt divided by all active loans.

These must not be combined into one default rate.

### Question 5: How do loan outcomes vary across point-in-time-safe pre-origination balance and inflow bands?

The project will examine whether recorded loan outcomes differ between accounts with stronger and weaker financial activity before loan origination.

Examples include comparing outcomes across:

* Pre-origination balance bands.
* Pre-origination external credit-inflow bands.
* Payment-to-inflow bands.

Only information available strictly before the loan origination date may be used.

The analysis is descriptive. It cannot establish that weaker balances or inflows caused a problem-loan outcome.

### Question 6: Which accounts satisfy transparent conditions for manual review?

The project will create a rules-based account-review list.

Possible review reasons include:

* Three consecutive months of negative net cash flow.
* A material six-month balance decline.
* A latest observed negative balance.
* A historically high-value relationship becoming dormant or lapsed.
* An active loan recorded in debt at the dataset endpoint.

The watchlist indicates which accounts a manager may wish to investigate. It is not a prediction of closure, churn, fraud or default.

### Question 7: What is the expected aggregate external credit inflow next month?

The project will produce a simple one-month-ahead forecast of external credit inflows across the account portfolio.

External credit inflows include eligible money entering accounts from outside the bank’s own interest and administrative postings.

This provides a basic planning estimate of incoming account cash. It is not:

* Bank revenue.
* Bank profit.
* Customer income.
* A complete forecast of the bank’s liquidity position.

---

## 6. Initial hypotheses

These hypotheses are written before analysing the results.

### Hypothesis 1: Positive account-balance growth may be concentrated among a small number of accounts

Total positive balances may increase even if most accounts experience little growth or declining balances.

A small number of high-balance accounts may account for a substantial share of the portfolio’s positive-balance growth.

This will be evaluated using total positive balances, median balances and top-10% balance concentration.

### Hypothesis 2: Activity retention may differ substantially across first-activity cohorts

Accounts that first record qualifying activity in different historical periods may show different subsequent activity patterns.

Some cohorts may continue recording activity for longer, while others may show rapid reductions in activity.

The data can identify these differences but cannot establish whether they were caused by marketing campaigns, acquisition quality or external economic conditions.

### Hypothesis 3: Completed problem loans may be associated with weaker pre-origination balances or inflows

Accounts with lower balances, weaker external inflows or higher payment-to-inflow ratios before loan origination may have a higher proportion of completed problem-loan outcomes.

Only strictly pre-origination information will be used.

Any relationship found is an association rather than evidence of causation.

### Hypothesis 4: Some historically valuable accounts may have become inactive by the final snapshot

Some accounts with historically strong balances or activity may record no recent qualifying activity by the final snapshot.

These accounts may be classified as dormant or lapsed for manual investigation.

Inactivity must not be described as confirmed customer churn because the dataset does not contain account-closing dates or reasons for inactivity.

---

## 7. Analytical safeguards

The project will follow these rules:

* Account-level values will never be duplicated across authorised clients.
* Accounts and clients will be counted and labelled separately.
* Demographic variables will remain descriptive.
* Positive balances will be presented as a deposit proxy.
* Loan status will be presented as an endpoint observation.
* No post-origination information will enter pre-origination loan metrics.
* External credit inflow will not be described as revenue, profit or complete bank liquidity.
* Account inactivity will not be described as confirmed churn.
* The account-review list will not be presented as a predictive risk model.
* Loan associations will not be presented as causal effects.
* The business findings will be written only after the analysis is complete.
