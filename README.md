# Zepto SQL Data Analysis

An end-to-end SQL project on Zepto's (quick-commerce grocery delivery) product catalogue — covering database design, data import, cleaning, exploration, and business-focused analysis using MySQL.

## Overview

This project takes a raw product export from Zepto and turns it into a clean, analysis-ready dataset, then answers a set of real business questions with SQL — the kind a pricing, marketing, inventory, or warehouse team would actually ask. It's built as a step-by-step workflow so each stage (setup → import → clean → explore → analyse) is easy to follow and re-run from scratch.

## Dataset

| | |
|---|---|
| **File** | `zepto_v.csv` |
| **Rows** | 3,732 product listings |
| **Columns** | `category`, `name`, `mrp`, `discountPercent`, `availableQuantity`, `discountedSellingPrice`, `weightInGms`, `outOfStock`, `quantity` |
| **Categories** | 14, including Fruits & Vegetables, Beverages, Personal Care, Packaged Food, Home & Cleaning, and more |

Prices in the raw file are stored in **paise** and are converted to rupees during cleaning.

## Tech Stack

- **Database:** MySQL 8
- **Language:** SQL (DDL, DML, aggregate functions, CASE expressions, CTEs, correlated subqueries)

## Project Structure

```
├── Zepto_SQL_data_Analysis.sql     # Full SQL script (setup → cleaning → analysis)
├── zepto_v.csv                     # Raw dataset
├── Zepto_SQL_Data_Analysis.pptx    # Presentation walking through the project
└── README.md                       # This file
```

## Workflow

The SQL script is organised into seven steps:

1. **Database & Table Setup** — creates the `zepto` database and table with explicit column types (`DECIMAL` for prices, `INT` for counts, `VARCHAR` for text) so calculations behave correctly from the start.
2. **Data Import** — loads the CSV into the table and verifies the import with `SELECT *` and `DESCRIBE`.
3. **Data Type Correction** — converts the `outOfStock` column from `'TRUE'`/`'FALSE'` text into a real `BOOLEAN`, a common fix needed when a raw import doesn't match the target column type.
4. **Data Exploration** — checks for missing values, lists all product categories, splits products by stock status, and flags duplicate product names.
5. **Data Cleaning** — removes rows with an invalid ₹0 price, then converts `mrp` and `discountedSellingPrice` from paise into rupees.
6. **Business Analysis Queries (Q1–Q8)** — straightforward aggregate and filter queries answering specific business questions.
7. **Advanced Analysis (Q9–Q12)** — uses CTEs combined with correlated subqueries in the `WHERE` clause to compare each product against its own category's benchmark.

## Business Questions Answered

| # | Question | Who uses it |
|---|---|---|
| Q1 | Top 10 best-value products by discount % | Merchandising |
| Q2 | High-MRP products that are out of stock | Inventory / Supply Chain |
| Q3 | Estimated revenue per category | Category Management |
| Q4 | Premium products with a weak discount | Pricing |
| Q5 | Top 5 categories by average discount % | Marketing |
| Q6 | Best price-per-gram value | Merchandising |
| Q7 | Weight-based tiers: Low / Medium / Bulk | Logistics |
| Q8 | Total inventory weight per category | Warehouse Planning |
| Q9 | Products priced above their category's average MRP | Pricing |
| Q10 | Out-of-stock products priced above category average | Inventory / Supply Chain |
| Q11 | Top-selling product in each category | Category Management |
| Q12 | Products cheaper per gram than their category average | Merchandising / Marketing |

## Key SQL Concepts Used

- Schema design with primary keys and appropriate data types
- `CASE` expressions for value remapping and tiering
- Aggregate functions (`SUM`, `AVG`, `MAX`, `COUNT`) with `GROUP BY`
- Data cleaning with `UPDATE` and `DELETE`
- Common Table Expressions (`WITH ... AS`)
- Correlated subqueries in the `WHERE` clause for group-wise comparisons

## How to Run

1. Open the script in MySQL Workbench (or your preferred MySQL client).
2. Run **Step 1** to create the database and table.
3. Import `zepto_v.csv` into the `zepto` table (Table Data Import Wizard, `LOAD DATA INFILE`, or any method of your choice).
4. Run **Steps 3–5** in order to correct data types and clean the data.
5. Run any query from **Steps 6–7** to explore the business insights.

## Author

**Krish Singh**
