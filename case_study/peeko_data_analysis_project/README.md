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
Data Cleaning & Feature Engineering
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

---
## Data Collection (Web Scraping)

* Imported the required libraries for making HTTP requests, parsing JSON responses, handling dataframes, and adding a delay between requests.
* Instead of scraping the visible HTML product cards, used FirstCry's internal search API to retrieve product listing data in JSON format.
* Identified the API endpoint and the parameters required to request different pages and search categories.
* Added request headers such as `User-Agent`, `Referer`, and `X-Requested-With` to make the request resemble a browser-generated request.
* Created a reusable `scrape_firstcry_category()` function so the same scraping logic could be applied to multiple categories without repeating the code.
* Used pagination to collect 20 products per page, with up to 50 pages per category, giving roughly 1,000 products per category.
* Requested each page sequentially and stopped early if the request failed or a page returned no products.
* The API response contained a JSON object with another JSON string inside `ProductResponse`, so the response was parsed in two steps to reach the actual product list.
* Extracted only the fields needed for the later competitive analysis rather than keeping the entire API response.

### Categories Scraped

* **Diapering** — searched FirstCry's diapering products.
* **Baby Food** — searched products related to baby food.
* **Baby Care** — searched products related to baby care.

Each category was passed through the same scraping function, keeping the collection process consistent across categories.

### Fields Collected

| Field            | Description                                                                                     |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| `product_name`   | Name of the product.                                                                            |
| `brand`          | Brand associated with the product.                                                              |
| `category`       | FirstCry's main category for the product.                                                       |
| `subcategory`    | More specific product classification.                                                           |
| `size`           | Product size or variant information.                                                            |
| `mrp`            | Listed maximum retail price.                                                                    |
| `discount_pct`   | Discount percentage offered.                                                                    |
| `selling_price`  | Actual selling price after discount.                                                            |
| `price_per_unit` | Price normalized to the relevant unit, useful for comparing products with different pack sizes. |
| `stock`          | Current stock value returned by the API.                                                        |
| `rating`         | Product rating.                                                                                 |
| `review_count`   | Review count returned by the API.                                                               |
| `source`         | Identifies FirstCry as the data source.                                                         |

**The scraping code is in `first_cry_scrapper`, and the final cleaned dataset is saved as `firstcry_competitor_data.csv`.**

---

## Data Cleaning & Feature Engineering

### Data Cleaning & Preparation

* **Initial inspection** → checked the dataset shape, column names, data types, and overall structure before starting the analysis.
* **Missing values** → checked all columns for missing values to make sure they would not cause problems later.
* **Column names** → changed column names to lowercase and replaced spaces or special characters to make them easier to use in Python.
* **Data types** → checked columns such as MRP, selling price, discount, stock, rating, and review count and made sure they had the correct numeric type.
* **Duplicate check** → checked for duplicate products using product name, brand, category, subcategory, and size.
* **Pricing checks** → checked that the selling price was not higher than the MRP and looked for unusual price values.
* **Rating checks** → checked that ratings were between 0 and 5.
* **Discount checks** → checked that discount percentages were between 0% and 100%.
* **Unneeded columns** → removed columns such as `source` and `search_category` after checking that they were not needed for the analysis.
* **Why these checks were done** → the data was already fairly clean because it came from a structured API, but these checks helped make sure the data was correct and that any mistakes from the scraping process did not affect the analysis.

**The output before feature engineering is saved as `firstcry_clean.csv`.**


---

###  Feature Engineering

Several new columns were created to make the product data more useful for the competitive and pricing analysis. The final prepared dataset contained **978 products**, with these new columns added for the competitive analysis.


* **`demand_signal`** → uses product rating as a simple signal of demand at the SKU level. Review count was not used because FirstCry's review count is linked to the parent product, not to each individual size variant.
* **`mrp_outlier_flag`** → flags products whose MRP is more than 50% higher than the median MRP of their subcategory. This helps find products with unusually high listed prices.
* **`discount_gap`** → shows how much a product's discount differs from the average discount in its subcategory. A positive value means the product has a higher discount than its peers, while a negative value means it has a lower discount.
* **`stock_pct_rank`** → ranks each product's stock level compared with other products in the same subcategory.
* **`stock_flag`** → groups the stock ranking into three simple categories: low, moderate, and healthy.
* **`ppu_rank`** → ranks products within their subcategory based on price per unit. This makes it easier to see which products are relatively cheaper or more expensive.
* **`sku_count`** → counts how many SKUs a brand has within each subcategory. This gives a simple view of how widely a brand is represented.

**The data cleaning and feature engineering code is in `firstcry_data_prep_and_feature_engineering`, and the final prepared dataset is saved as `firstcry_final_data.csv`.**


---

 


