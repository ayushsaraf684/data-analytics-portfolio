# Road Accidents Dashboard (Tableau)

## Dashboard Screenshot
(<img width="3200" height="1800" alt="Accident Dashboard SS" src="https://github.com/user-attachments/assets/719bb3bc-e527-452d-be56-471405fe5970" />
)

---

Road accident data sounds dry until you start poking at it. Then you find things like 81% of serious casualties happened in fine weather. Or that fatal accidents dropped nearly 18% in 2020. And you start asking why.

That curiosity is what this project is really about.

---

## The Data

Great Britain road accident records for 2019 and 2020. Severity breakdown across Fatal, Serious, and Slight casualties. Covers vehicle types, weather conditions, road surfaces, road types, and geographic location.

One CSV. One Tableau workbook. Nothing fancy on the data side — the interesting part was figuring out what to ask.

---

## What I Built

- KPI cards with sparklines tracking Total Accidents, Total Casualties, Fatal, Serious, and Slight — all with YoY movement
- Vehicle type breakdown using icons because numbers alone do not tell you that  cars are involved in 26,000+ serious casualties while agricultural vehicles  sit at 92
- Two donut charts — one for weather conditions, one for road surface — because I wanted to test the assumption that bad weather = more accidents (spoiler: it does not hold)
- Horizontal bar chart for road types — single carriageways are not even close
- A geographic map plotting casualty hotspots across Great Britain

---

## Things That Actually Surprised Me

**Fine weather. Dry roads. Most casualties.** 81% of serious casualties in fine weather. 65% on dry surfaces. The data keeps telling you that conditions are not the problem — behavior is.

**Fatal casualties fell 17.81% YoY.** Steepest drop across all severity levels. 2020 data. Make of that what you will — COVID lockdowns likely cut traffic volume significantly, which shows up here.

**Single carriageways at 1,69,943 serious casualties.** The next closest is dual carriageways at 37,960. That gap is not a rounding error. That is a policy conversation.

**Cars at 26,367 serious casualties vs buses at 1,347.** Volume explains some of this but not all of it.

---

## Tools

Tableau Desktop for everything visual. The dataset came as a CSV — no cleaning pipeline, no Python here. Raw data in, dashboard out.

---

## Honest Note

Built this while learning Tableau. Followed a YouTube tutorial to get started, but stayed because the data was actually interesting. This started as a tutorial follow-along. The build process was guided. The observations and the README are mine. Uploading it because practice projects deserve documentation too and because the data had more to say than I expected
