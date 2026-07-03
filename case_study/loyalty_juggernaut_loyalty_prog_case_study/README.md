# Kinara Kirana Loyalty Program Analytics
### A simulation project, built out of curiosity

---

## Why this exists

I came across Loyalty Juggernaut's GRAVTY platform while researching what a real loyalty analytics stack looks like at enterprise scale — and honestly, it messed with my head a little.

I had no idea loyalty programs were this complex behind the scenes. Points liability. Tier engineering. Redemption behavior. Churn signals *inside* a program that is supposed to prevent churn. It felt like a puzzle I wanted to poke at myself, so I built one.

**Kinara Kirana** is not a real company. It is a made-up Indian retail brand with a three-tier loyalty program (Silver, Gold, Platinum) running across 12 cities. This project is me simulating what a BI analyst would actually do if they were handed this member database on day one.

This is a simulation, built purely out of interest in how loyalty programs work. If something looks slightly off or naive in places, that is expected — this was a learning project first and a portfolio piece second. I would genuinely welcome any feedback on where the logic breaks down.

---

## What is inside this repo

kinara-kirana-loyalty-analysis/
├── raw_data/
│   └── kinara_kirana_loyalty_raw.xlsx          # original messy dataset
├── processed_data/
│   └── kinara_kirana_loyalty_raw.csv      # cleaned and enriched output
├── Data prep.ipynb # full Python notebook
├── SQL E.D.A..sql                     # all 5 SQL findings
├── Analysis Deck.pdf          # slide deck with findings
└── README.md



**Stack used:** Python (Pandas), PostgreSQL, Tableau, Excel

---

## Step 1 — Where it started: a very messy spreadsheet

I opened the raw file expecting a clean member database. What I got instead was this:

| Issue | What I found |
|---|---|
| City spelling variants | Banglore, Bengalru, Bangalore — all meant Bengaluru |
| Tier inconsistencies | silver, SILVER, Silvr, Golld — same tier, four different strings |
| Whitespace | hiding inside columns where you would never think to look |
| Impossible dates | 55 rows where join date came *after* last transaction date |
| Null values | city, coupon redemptions, referral count |
| Negative spend | a handful of rows with values like -47,164 |
| Points violation | 7 members who had redeemed more points than they ever earned |

None of this was dramatic on its own. But stacked together it was a genuine data quality audit, not just a cleanup pass.

I went column by column, flagged every issue, decided on a fix, and wrote down the reasoning before touching the data. Looking back, that documentation step ended up being more valuable than the fixes themselves — it forced me to justify every decision instead of just deleting anything that looked weird.

**A few judgment calls worth noting:**

- The 55 rows with bad join dates — instead of deleting those members, I reset their last transaction date to the reference date. Throwing away a customer's entire history over one bad date field felt like the wrong call.
- Negative spend — flipped to absolute value. The transaction happened, only the sign was wrong.
- Points violations — capped redeemed at earned. Likely a historical carry-over from outside the data window.
- Null coupon redemptions and referral counts — filled with zero. A missing value there almost certainly means no activity happened, not that data got lost.

**Result:** 2,374 messy rows → 2,320 clean ones.

> Full cleaning logic and reasoning is documented as markdown cells inside the notebook.

---

## Step 2 — Feature engineering: asking the data real questions

Cleaning gets you a usable dataset. Feature engineering is where you start asking it real questions.

**Four features engineered in Python:**

**`days_since_last_txn`**
How many days since a member last transacted, measured from a fixed reference date (June 30, 2026). Simple, but it powers most of the churn logic downstream.

**`points_unredeemed`**
Total points earned minus total points redeemed. Every unredeemed point is technically money the brand owes the customer — so this column is a liability measure, not just a balance.

**`churn_signal`**
Flagged 1 if a member has not transacted in more than 90 days. 90 days is a common retail disengagement threshold.

**`high_value_flag`**
Flagged 1 if a member's average basket value is in the top 25% of the dataset.

**Three features calculated in SQL (not Python):**

**`engagement_score`**
A composite behavioral index combining three signals — transaction count, coupon redemptions, and referral count — each normalized to a 0–10 scale using max normalization, then averaged.

Why max normalization and not min-max? Because if someone has never referred anyone, they should score a flat zero on that dimension. Min-max would artificially bump them up just for being the dataset minimum. Zero should mean zero.

**`redemption_rate`**
Points redeemed divided by points earned. Calculated per member inside SQL using `NULLIF` to avoid divide-by-zero errors.

**`points_liability_flag`**
Flagged 1 if a member's redemption rate is below 10% AND their unredeemed points are above 5,000.

Neither number was picked arbitrarily:
- 5,000 sits at the **75th percentile** of unredeemed balances
- 10% sits at the **25th percentile** of redemption rates

So the flag only catches members who are genuinely hoarding points relative to everyone else — not just marginally below average.

---

## Step 3 — SQL analysis: is this program actually working?

Once the clean data landed in PostgreSQL, I wrote five queries to answer one core question:

> **Is this loyalty program creating loyal behavior, or is it just tracking transactions with tier labels stuck on top?**

Here is what came out.

---

### Finding 1 — The engagement score cannot tell active from churned

| Tier | Dormant | Churn Risk | Active |
|---|---|---|---|
| Gold | 137 members \| 4.14% | 77 members \| 3.96% | 304 members \| 3.96% |
| Platinum | 44 members \| 5.59% | 18 members \| 5.42% | 74 members \| 5.43% |
| Silver | 504 members \| 3.59% | 237 members \| 3.46% | 925 members \| 3.47% |

Engagement scores are nearly identical across Active, Dormant, and Churn Risk members within every tier. A well-designed loyalty program should show meaningfully higher engagement for active members. The flat distribution suggests the program is not driving differentiated behavior — it cannot distinguish its most engaged members from the ones who have already left.

---

### Finding 2 — The longer a member stays, the more likely they are to churn

| Join Year | Total Members | Churned | Churn Rate |
|---|---|---|---|
| 2022 | 308 | 83 | **26.95%** |
| 2023 | 613 | 151 | 24.63% |
| 2024 | 567 | 133 | 23.46% |
| 2025 | 595 | 130 | 21.85% |
| 2026 | 237 | 16 | 6.75% |

Members who joined in 2022 churn at nearly 4x the rate of 2026 joiners. The program is not doing enough to retain long-tenure members — the people who have been around the longest are the ones walking away.

---

### Finding 3 — The brand's biggest per-member liability is in its smallest segment

| Tier | Members | Total Unredeemed Points | Avg Per Member |
|---|---|---|---|
| Platinum | 136 | 3,621,677 | **26,629** |
| Gold | 518 | 4,966,944 | 9,588 |
| Silver | 1,666 | 3,166,999 | 1,900 |

Platinum members hold 14x more unredeemed points per person than Silver members. The brand's biggest per-member financial liability is concentrated in its smallest and most valuable segment. If Platinum members redeem in a wave, it creates a significant cost spike.

---

### Finding 4 — Everyone watches Platinum. The real risk is Gold.

| Tier | Total Members | Liability Members | Liability % | Points at Risk |
|---|---|---|---|---|
| Gold | 518 | 126 | **24.32%** | 4,966,944 |
| Platinum | 136 | 31 | 22.79% | 3,621,677 |
| Silver | 1,666 | 72 | 4.32% | 3,166,999 |

24.32% of Gold members meet the liability threshold — slightly higher than Platinum. Gold is the hidden risk tier. They are numerous enough to matter at scale, and they are hoarding points at nearly the same rate as the most elite segment.

---

### Finding 5 — Platinum spends 13x more than Silver but redeems at the same rate

| Tier | Avg Spend | Avg Transactions | Avg Redemption Rate | Avg Referrals |
|---|---|---|---|---|
| Platinum | ₹4,16,880 | 37.50 | 36.73% | 2.64 |
| Gold | ₹1,52,557 | 13.15 | 37.75% | 2.51 |
| Silver | ₹30,564 | 4.43 | 37.90% | 2.48 |

Redemption rate is almost identical across all three tiers. Referral behavior is flat too. The tier structure exists on paper but not in behavior — the program is capturing spend, but it is not converting higher-tier members into more engaged or more loyal customers.

---

## Step 4 — The dashboard

I built a Tableau dashboard on top of all this — because a stakeholder is never going to read a SQL file. They are going to look at a screen for ten seconds and want the story handed to them.

![Kinara Kirana Customer Dashboard](https://github.com/user-attachments/assets/b353ae73-fb58-4a01-aec3-6e98ebd2c18c)

**What is on it:**

- KPI cards up front — total members, total revenue, avg spend, avg basket value, points liability, avg engagement score, redemption rate, high value customer count
- Revenue by tier — Gold actually brings in more total revenue than Platinum, simply because there are far more Gold members. The flashiest tier is not always where the money lives.
- Spend vs engagement scatter — Platinum members cluster high on spend but scatter all over on engagement. High spend does not automatically mean high engagement.
- Acquisition channel breakdown — where the highest spending customers are actually coming from
- Membership status vs high value flag — how high value customers are distributed across active, dormant, and churn risk segments
- Slicers for category, channel, membership status, gender, city, and tier

---

## What I took away from this

I went into this thinking loyalty programs were a fairly simple concept — points in, points out, tiers as a reward ladder.

I came out the other side realizing there is a lot more tension underneath that surface. Between rewarding customers and managing the liability those rewards create. Between making a tier feel exclusive and that tier actually *behaving* any differently from the one below it.

This was a simulation, built with a fictional company and a generated dataset. But the process behind it — the cleaning, the reasoning, the feature building, the querying — was as real as I could make it.

If I got something wrong along the way, I would genuinely like to know.

---

> **P.S.** The SQL file is a little rough in places. I lost a chunk of the queries mid-project and had to rewrite them from memory. They work, but they are not the prettiest.

> **P.P.S.** I loved the name. Initially thought of something like AyushKart or Little Grain, but Kinara Kirana is fire.

---

**Built by Ayush Saraf**
