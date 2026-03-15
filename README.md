# Root Cause Analysis — Uber Ride Completion Decline

## View Full Presentation and SQL analysis in the files

## Project Overview

Uber's platform recorded a **34% decline in completed rides during Q3**, 
while ride bookings remained relatively stable across the same period. 
This divergence between demand and fulfillment signals a systemic 
operational failure — not a loss of customer interest.

This project conducts a full Root Cause Analysis (RCA) using SQL to 
dissect ride completion patterns, cancellation behavior, payment 
reliability, and driver payout efficiency across cities, ride types, 
and quarters, culminating in data-backed recommendations to 
restore platform performance.

## Business Problem

> *"Customers are booking rides. The rides are not being completed. Why?"*

A drop in completed rides — while bookings hold steady — points to 
a fulfillment breakdown somewhere between booking confirmation and 
ride completion. Left unaddressed, this directly erodes:

- **Platform revenue** — fewer completions mean fewer transactions
- **Driver trust** — unreliable payouts reduce driver willingness 
to accept rides
- **Customer experience** — failed rides increase churn, 
especially in high-demand urban markets

The objective of this analysis is to isolate *where* in the 
fulfillment chain the breakdown occurs and *what* is driving it.

## Tools

**MySQL** - Data cleaning, deduplication, exploratory analysis, RCA queries using CTEs and Window Functions
**Power BI** - DAX measures, KPI cards, bar charts, clustered column charts
**PowerPoint** - Executive presentation of findings and recommendations

## Key Metrics

| Metric | Value |
|--------|-------|
| Overall Ride Completion Rate | **84.80%** |
| Driver Cancellation Rate | **7.80%** |
| User Cancellation Rate | **7.40%** |
| Overall Payment Failure Rate | **10.14%** |
| Payout Delay Rate | **1.89%** |

## Analysis & Findings

### 1. Ride Completion Performance by Ride Type

| Ride Type | Completion Rate |
|-----------|----------------|
| Prime | 87.04% |
| Auto | 84.09% |
| Mini | 83.33% |

**Finding:** While Prime rides lead in completion rate, 
the gap across all three ride types is narrow (less than 4 
percentage points). This rules out ride type as the primary 
driver of the Q3 decline — the problem is not isolated to 
one service category. The drop is platform-wide, pointing 
toward a systemic cause rather than a product-specific one.

### 2. User vs Driver Cancellation Rate by City and Ride Type

| City | Ride Type | User Cancellation | Driver Cancellation |
|------|-----------|------------------|-------------------|
| Mumbai | Auto | 4.84% | **16.13%** |
| Mumbai | Prime | 4.26% | **12.77%** |
| Mumbai | Mini | 10.14% | 10.14% |
| Delhi | Mini | **13.73%** | 3.92% |
| Delhi | Auto | **10.20%** | 6.12% |
| Bangalore | Auto | 7.69% | 3.08% |

**Finding:** Two distinct cancellation patterns emerge 
by geography:

- **Mumbai is a driver-side problem.** Driver cancellations 
in Auto (16.13%) and Prime (12.77%) are disproportionately 
high, strongly suggesting dissatisfaction with payout 
reliability or incentive structure — not a lack of demand.

- **Delhi is a user-side problem.** High user cancellations 
in Mini (13.73%) and Auto (10.20%) point to price sensitivity, 
longer-than-expected wait times, or a friction point in 
the booking experience.

- **Bangalore is relatively stable**, with balanced 
cancellation rates — making it a useful control benchmark 
for further investigation.

### 3. Payment Failure Rate by Payment Mode

| Payment Mode | Failure Rate |
|-------------|-------------|
| GPay | **13.04%** |
| Cash | 9.15% |
| Card | 8.33% |

**Finding:** GPay carries a significantly higher failure 
rate than both Cash and Card. This is a critical operational 
risk — GPay is a widely adopted payment mode in urban India, 
meaning its failures affect a large volume of transactions. 
A 13% failure rate at the payment stage directly translates 
to incomplete ride settlements, driver dissatisfaction, 
and user frustration.

*Note: Payment failure rates were calculated exclusively 
on completed rides to isolate payment processing issues 
from ride cancellation effects.*

### 4. Payment Success Rate by Payment Mode

| Payment Mode | Success Rate |
|-------------|-------------|
| Card | **78.11%** |
| Cash | 77.25% |
| GPay | 73.17% |

**Finding:** Card is the most reliable payment method, 
followed closely by Cash. GPay's success rate of 73.17% 
sits nearly 5 percentage points below Card — a meaningful 
gap when scaled across thousands of daily transactions. 
Improving GPay's reliability to match Card levels would 
directly improve overall platform payment performance.

### 5. Driver Payout Delay Analysis

| Payment Status | Payout Status | No. of Drivers | Avg Delay |
|---------------|--------------|----------------|-----------|
| Success | Processed | 746 | 0.97 days |
| Success | Delayed | 16 | 4.98 days |
| Failed | Pending | **86** | Still delayed |

**Finding:** While the majority of drivers (746) receive 
payouts within 24 hours, two groups warrant immediate attention:

- **16 drivers** waited nearly **5 days** for payouts 
despite successful payments — a clear processing failure
- **86 drivers** have payments still pending with no 
resolution — representing failed transactions that were 
never recovered

Delayed payouts directly erode driver trust. When drivers 
cannot rely on timely payments, they are incentivized to 
request cash directly from customers — bypassing the app 
entirely and reducing platform revenue visibility.

### 6. Quarterly Ride Completion Trend — RCA

| Quarter | Completion Change |
|---------|-----------------|
| Q1 | +0.53% |
| Q2 | **+45.57%** |
| Q3 | **-34.24%** |
| Q4 | +5.75% |

**Finding:** The quarterly trend tells a clear story:

- **Q2's surge (+45.57%)** likely reflects peak demand 
or a successful operational period — establishing a 
high baseline that makes Q3's fall more pronounced
- **Q3's collapse (-34.24%)** is not a demand problem. 
Bookings remained stable while completions fell sharply, 
pointing directly to fulfillment failure driven by 
GPay payment issues and driver payout delays
- **Q4's partial recovery (+5.75%)** is the most important 
signal in the dataset — it confirms the platform responds 
quickly to operational fixes, meaning targeted interventions 
will produce measurable results within a single quarter

**The core narrative:** Payment reliability broke down in Q3. 
Drivers lost trust due to payout delays. GPay failures 
disrupted settlements. Together, these compounded into 
a 34% fulfillment collapse — all while demand held steady.

## Actionable Recommendations

### Payment Infrastructure
- **Resolve GPay's 13.04% failure rate** by coordinating 
directly with GPay's technical team — this is the single 
highest-impact fix available
- **Introduce automatic payment fallback** — if GPay fails, 
instantly prompt the user to switch to Cash or Card 
before the ride is cancelled

### Driver Trust & Retention
- **Enforce 24-hour payout processing** with automated 
alerts for any payout exceeding this threshold — 
prioritize clearing the 86 currently pending payouts immediately
- **Add transparent fare breakdowns** in the driver app 
so drivers see exactly what they earn per ride, 
reducing distrust-driven cancellations
- **Introduce Q3 completion bonuses** to maintain driver 
acceptance rates during historically weaker quarters

### City-Specific Interventions
- **Mumbai** — Investigate driver incentive structure 
and payout reliability; high driver cancellations 
signal a supply-side trust problem
- **Delhi** — Run price sensitivity analysis on Mini 
and Auto rides; reduce wait time estimates to better 
manage user expectations and reduce user-side cancellations
- **Bangalore** — Monitor as a control market; 
use its balanced metrics as a benchmark for 
evaluating intervention effectiveness elsewhere
