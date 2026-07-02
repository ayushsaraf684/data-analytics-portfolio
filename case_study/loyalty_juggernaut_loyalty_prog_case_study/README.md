# Kinara Kirana Loyalty Program Analytics

### A simulation project, built out of curiosity

## Why this exists

I came across Loyalty Juggernaut's GRAVTY platform while looking into what a real loyalty analytics stack looks like at enterprise scale, and honestly, it messed with my head a little. I had no idea loyalty programs were this complex behind the scenes. Points liability, tier engineering, redemption behavior, churn signals inside a program that's supposed to prevent churn. It felt like a puzzle I wanted to poke at myself, so I built one.

Kinara Kirana is not a real company. It's a made up Indian retail brand with a three tier loyalty program (Silver, Gold, Platinum) running across 12 cities, and this whole project is me trying to simulate what a BI analyst would actually do if they were handed this member database on day one.

This is a simulation, made purely out of interest in how loyalty programs work. If something in here looks slightly off or naive in places, that is expected, this was a learning project first and a portfolio piece second. I would genuinely welcome any feedback on where the logic breaks down.

## Where it started: a very messy spreadsheet

I opened the raw file expecting a clean member database. What I got instead was a mess, and honestly that mess turned out to be the most useful part of the whole project because it forced me to actually think like an analyst instead of just running functions.

Some of what I found staring back at me:

- City names spelled five different ways. Banglore, Bangalore, Bengalru, all supposed to be Bengaluru. Mumabi and Mumbi both meant Mumbai.
- Tier values written as silver, SILVER, Silvr, Golld. Same tier, four different strings.
- Whitespace hiding inside columns where you'd never think to look for it.
- 55 rows where the join date came after the last transaction date, which makes no logical sense for a member record.
- Null cities, null coupon redemptions, null referral counts.
- Negative total spend on a handful of rows, which obviously cannot exist in real life.
- 7 rows where a member had redeemed more points than they'd even earned.

None of this was dramatic on its own, but stacked together it was a genuine data quality audit, not just a cleanup pass. I went column by column, flagged every issue, decided on a fix, and wrote down the reasoning for each one before touching the data. Looking back, that documentation step ended up being more valuable than the fixes themselves, because it forced me to justify every decision instead of just deleting anything that looked weird.

The fixes themselves were mostly judgment calls dressed up as code. Standardize the spelling. Strip the whitespace. For the join date problem, instead of deleting those 55 members, I reset their last transaction date to a fixed reference point, because throwing away a customer's entire history over one bad date field felt like the wrong call. Negative spend got flipped to absolute value. The points violation got capped so redeemed never exceeds earned. Nulls in coupon redemptions and referral count got filled with zero, because a missing value there almost certainly means no activity happened, not that the data got lost somewhere.

By the end I had gone from 2,374 messy rows down to 2,320 clean ones, and for the first time the dataset actually made logical sense.

## The part where things got interesting: feature engineering

Cleaning gets you a usable dataset. Feature engineering is where you start asking it real questions.

The one I kept coming back to was engagement. A loyalty program isn't really about how much someone spends, it's about whether they stay engaged with the program itself, and spend alone doesn't tell you that. So I built something called an engagement score, and figuring out how to build it properly took a few wrong turns before it clicked.

The idea is simple once you see it. A member who transacts a lot is engaged. A member who redeems a lot of coupons is engaged. A member who refers friends is very engaged. But none of those three signals alone tells the full story, someone could transact constantly and never redeem anything, or refer a bunch of friends and barely shop themselves. So I took all three signals, transaction count, coupon redemptions, referral count, normalized each one to a 0 to 10 scale by dividing by the column's maximum, and averaged them into one number per member.

I went with max normalization instead of min-max, and this took me a minute to reason through properly. Min-max stretches the lowest value in the dataset up to 0 and the highest up to 10, which sounds fine until you realize it artificially inflates the score of your least active member just because they happen to be the minimum. Max normalization keeps zero meaning zero. If someone has never referred anyone, they should score a flat zero on that dimension, not get bumped up just for existing in the dataset. That felt like the more honest choice for behavioral data that has a real, natural floor.

The other feature I spent real time on was points liability. Every unredeemed point sitting in a member's account is technically money the brand owes, so a member with a huge point balance and almost no redemption activity is a quiet financial risk. I flagged anyone whose redemption rate was below 10% and whose unredeemed points were above 5,000, and neither number was picked out of thin air, both came straight from the data itself. The 5,000 figure sits at the 75th percentile of unredeemed balances, and the 10% rate sits at the 25th percentile of redemption rates. So the flag only catches members who are genuinely hoarding points relative to everyone else, not just marginally below average.

Small oversight I'll admit to: coupon_redemptions and referral_count still had a few nulls slip through into the exported SQL table before I filled them properly in Pandas. Caught it after the fact, fixed it, but leaving it in here because pretending the pipeline was flawless the first time through would be dishonest.

## Then it went into SQL, and that's where the real digging happened

Once the clean data landed in PostgreSQL, I wrote a set of queries meant to answer one core question: is this loyalty program actually working, or is it just tracking transactions with tier labels stuck on top?

I won't lay out every query and result here since that lives in the SQL file itself, but I'll say this much, some of what came out surprised me. There were numbers that looked completely unremarkable on the surface, average this, average that, until I sliced them by tier or by cohort and a pattern showed up that had no business being there. A few findings genuinely made me sit back and go "wait, that's not supposed to happen in a loyalty program." I'll let the SQL analysis speak for itself rather than spoil it here, but the short version is that the program looks healthier on paper than it actually behaves underneath.

## The dashboard

I built a Tableau dashboard on top of all this called the Kinara Kirana Customer Dashboard, mainly because a stakeholder is never going to read a SQL file, they're going to look at a screen for ten seconds and want the story handed to them.


<img width="893" height="504" alt="image" src="https://github.com/user-attachments/assets/b353ae73-fb58-4a01-aec3-6e98ebd2c18c" />


It's got the top line numbers up front, total members, total revenue, average spend per customer, average basket value, total points liability, average engagement score, average redemption rate, and a count of high value customers, so anyone glancing at it gets the pulse of the program immediately.

Below that sits a revenue by tier chart, and this one alone tells a small story, Gold actually brings in more total revenue than Platinum despite being the "middle" tier, simply because there are so many more Gold members. It's a good reminder that the flashiest tier isn't always where the money lives.

The spend versus engagement scatter plot was probably my favorite thing to build. Each dot is a member, sized and colored by tier, plotted against their engagement score and total spend, with median lines cutting through both axes. What jumps out immediately is that Platinum members cluster high on spend but are scattered all over the place on engagement, meaning high spend does not automatically mean high engagement. That single chart visually backs up a lot of what the SQL findings were already hinting at.

The acquisition channel breakdown shows where the highest spending customers are actually coming from, and the membership status versus high value flag chart shows how those high value customers are distributed across active, dormant, and churn risk segments, which is a slightly uncomfortable but useful thing for a business to see.

Slicers for category, channel, membership status, gender, city, and tier sit on the side so anyone using this could actually filter and explore it themselves instead of just staring at my conclusions.

## Closing thoughts


I went into this thinking loyalty programs were a fairly simple concept, points in, points out, tiers as a reward ladder. I came out the other side realizing there's a lot more tension underneath that surface, between rewarding customers and managing the liability those rewards create, between making a tier feel exclusive and that tier actually behaving any differently from the one below it.

This was a simulation, built with a fictional company and a generated dataset, but the process behind it, the cleaning, the reasoning, the feature building, the querying, was as real as I could make it. If I got something wrong along the way, I'd genuinely like to know, that's most of the reason I built this in the first place.

** P.S. :- The SQL codes are a little dirty. I lost a major chunk of them while working on this project, so I had to rewrite them from the best of my memory.**
** P.P.S. :- I loved the name, initially thought of keeping something cool like AyushKart or Little Grain, but this one is fire!!!.**


---

**Stack used:** Python (Pandas), PostgreSQL, Tableau, Excel

**Built by:** Ayush Saraf
