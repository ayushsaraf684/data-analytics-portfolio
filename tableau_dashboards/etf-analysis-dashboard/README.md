# US ETF Analysis Dashboard

A financial analytics dashboard built in Tableau analyzing 76 US Exchange Traded Funds across Equity, Fixed Income, Commodity, Multi-Asset, and Real Estate categories.

![Dashboard Screenshot](<img width="3200" height="1800" alt="Dashboard 1" src="https://github.com/user-attachments/assets/764ac280-ab1c-4a69-b2c4-64045feb10f3" />

---

## What This Project Does

This dashboard lets you explore ETF performance, risk, and price trends dynamically. You can switch between 1 month, 3 month, and 6 month return periods and more and the entire dashboard updates instantly.

Built this as someone who had zero knowledge of ETFs or financial markets, purely out of curiosity and to understand how wealth management data actually works.

---

## Dashboard Features

- **Return Comparison by Asset Class** — which asset classes (Equity, Fixed Income, Commodity etc.) performed best over your selected time period
- **Top and Bottom ETF Performers** — ranked bar chart showing the best and worst individual ETFs by average return
- **Risk vs Return Scatter Plot** — plots every ETF by its 30-day volatility against its return. Helps identify which ETFs give the best reward for the risk taken
- **ETF Price Trendline** — historical close price chart from 2021 to 2026, filterable by individual ETF
- **Asset Class Treemap** — visual breakdown of the ETF universe by category
- **KPI Cards** — total ETFs tracked, average market return, and best performing ETF for the selected period

---

## Key Insights (3 Month Returns)

- **United States Oil Fund returned 59.6%** in 3 months, the highest of any ETF in the dataset
- **Technology Select Sector SPDR returned 34.8%** but also showed the highest volatility in the entire dataset — high reward, high risk
- **Fixed Income ETFs were negative across the board** — iShares TIPS Bond ETF showed an extreme negative return which flagged as a potential data anomaly worth investigating
- **iShares Core Aggressive Allocation ETF** sat in the ideal zone on the scatter plot — decent return with the lowest volatility in the chart. This is the kind of positioning wealth managers target for client portfolios
- **iShares Silver Trust** showed the worst risk-return combination — high volatility paired with a -19.6% return. Maximum risk, negative reward
- **iShares MSCI India ETF returned -6.9%** during a period when US equity was strongly positive, highlighting the divergence between emerging market and domestic performance

---

## Tools Used

- **Python** — data extraction using the yfinance library
- **Tableau Desktop** — dashboard design and visualization

---

## How to Reproduce the Data
Check out the Jupyter Notebook uploaded in this repo, directly run that
Make sure that you have the necessary libraries installed

This generates two CSV files:

- `etf_price_history.csv` — one row per ETF per trading day, approximately 95,000 rows covering 5 years of price history
- `etf_summary_returns.csv` — one row per ETF with pre-calculated returns across 1M, 3M, 6M, 1Y, 3Y, and 5Y timeframes

---

## Repository Structure

```
etf-analysis-dashboard/
│
├── data/
│   ├── etf_price_history.csv
│   └── etf_summary_returns.csv
│
├── pull_etf_data.py
├── dashboard_screenshot.png
└── README.md
```

---

## About

Built by Ayush Saraf — BCom Honours graduate exploring data analytics and financial markets.

Connect with me on [LinkedIn](https://www.linkedin.com/in/sarafayush/)
Watch my Youtube Videos @ [Ayush Queries](https://www.youtube.com/@ayushqueries)
