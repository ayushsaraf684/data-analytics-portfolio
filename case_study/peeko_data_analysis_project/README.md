Quick heads-up: the next couple of paragraphs are just me being dramatic. If you're here for the actual project, feel free to skip straight to "Why I Built This" or the technical sections below

## Storytelling Time

A few days ago, I came across the Data Analyst opening at Peeko, and honestly, I got hooked. Not just because it was a job posting, but because of what they're actually building. Quick commerce for baby products, sub-60-minute delivery, the whole thing just made sense to me the second I read it.

And then my brain, being the dramatic thing that it is, immediately jumped to: Picture a 32-year-old guy living in Koramangala, Bengaluru. Late one night, his baby girl is crying, and he realizes, mid-panic, that he forgot to restock diapers. No 24-hour store nearby, no way to get them in time, just him standing in his kitchen questioning his life choices. What does his wife do? She will *literally* kill him, and threaten to go back to her mother's place (Although wives leave, men get peace. Pun very much intended.).

Jokes aside, that whole chaotic scenario is basically Peeko's entire business case in one sentence: parents don't have time to deal with running out of essentials at the worst possible moment. So I thought, instead of just sending a resume into the void, why not build something that shows I actually get this problem and can work with the kind of data that solves it.

That's where this project came from.

---

## Why I Built This

The story about the man I was talking above, that exact gap is what Peeko is trying to close. Speed, relevance, and convenience, for a category that genuinely cannot wait till morning.

Now, the real reason I built this: I am a fresher, and I know that on paper, my resume doesn't scream "traditional data analyst candidate." So instead of hoping a recruiter takes a bet on me, I wanted to actually show what I can do, that I understand data (scraping it, cleaning it, engineering features out of it), and more importantly, that I understand *Peeko's* business, not just data analysis in the abstract.

---

## Structure of this README:

Storytelling / Why I Built This
Project Overview
Data Collection (Web Scraping)
Data Cleaning
Feature Engineering
EDA & Insights (in progress)

---

## Project Overview

This project is an end-to-end data analysis pipeline built around products relevant to Peeko's business. I scraped product-level data, cleaned it, engineered features to surface business-relevant signals, and ran exploratory analysis to pull out patterns around pricing, categories, and product performance, essentially mimicking the kind of data work the Peeko Data Analyst role revolves around.

What is FirstCry?
FirstCry is India's largest online marketplace for baby, kids', and maternity products, selling everything from apparel and footwear to toys, diapers, feeding essentials, and maternity wear across hundreds of brands. It's essentially the go-to destination for parents shopping for their kids online in India.

Why FirstCry data, for a Peeko project?
FirstCry sells across a huge range of categories, boys' fashion, girls' fashion, maternity wear, school essentials, and a lot more that falls outside what Peeko actually deals in. Peeko, on the other hand, runs a much more focused assortment built specifically for its 60-minute delivery model. Based on their own category listings, that assortment centers around things like Diaper & Wipes, Baby Food, Feeding & Nursing, Personal Care & Baby Care, Health & Hygiene, Toys, Boy & Girl Fashion, and Daily Essentials.

So instead of scraping FirstCry broadly, I narrowed the scope to only the categories that actually overlap with what Peeko sells, since that's what makes the analysis relevant to their business instead of just being a generic e-commerce scrape.

Scope of this project:
I scraped data from 3 categories (diapering, baby food, baby care) that map directly onto Peeko's core assortment. The full scraping code is available as **'first_cry_scrapper.ipynb'**
