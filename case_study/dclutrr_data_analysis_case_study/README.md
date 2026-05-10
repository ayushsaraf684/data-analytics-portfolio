# Quick Commerce Data Standardization Pipeline

## Problem

Blinkit, Zepto, and Instamart each export sales data differently.
Different column names, date formats, SKU naming conventions, and 
data quality standards make cross-platform analysis difficult 
without proper standardization.

This project simulates that problem and builds a solution.

---

## What This Project Does

A Python pipeline imports raw exports from three platforms,
standardizes them into a unified schema, and loads the output
into PostgreSQL for analytical querying.

---


## Pipeline Steps

1. Load raw CSV exports from all three platforms
2. Rename columns to unified schema
3. Standardize date formats 
4. Standardize city names and SKU name variants
5. Flag missing revenue and zero quantity rows
6. Merge into single unified output

---

## SQL Analysis — Key Findings

**Finding 1 — Price Variance Across Platforms**
The same SKU is priced up to 72% differently across platforms.
Identified using implied price per unit aggregated at platform level.

**Finding 2 — Data Quality Audit**
Zepto had 6 rows with missing revenue values.
Instamart had 6 rows with zero quantity sold.
Blinkit had no data quality issues.

**Finding 3 — SKU Concentration Risk**
Several platform-city combinations show one SKU driving
60%+ of total revenue — a significant operational risk
if that SKU goes out of stock.

---

## Tools Used

- Python 3, Pandas, Jupyter Notebook
- PostgreSQL
- Data: Synthetic mock data simulating real platform exports (generated using GenAI Tools)

---

## Case Study Deck

Full presentation with problem statement, pipeline overview,
and findings available in the repository.
