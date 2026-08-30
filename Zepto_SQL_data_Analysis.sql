-- ============================================================
-- PROJECT     : Zepto SQL Data Analysis
-- DESCRIPTION : End-to-end SQL workflow on Zepto's product catalogue —
--               schema design, data import, cleaning, exploration,
--               and business-focused analysis queries.
-- ============================================================


-- ============================================================
-- STEP 1: DATABASE & TABLE SETUP
-- Goal: Create a clean, correctly typed home for the raw data
--       before anything is loaded into it.
-- ============================================================

-- Drop the database first so this script can be re-run from a
-- clean slate every time, without leftover data from a previous run.
drop database if exists Zepto;

-- Create a dedicated database to store the Zepto product data.
create database zepto;

use zepto ;

--  ================= step 1: Craete a table =====================

-- Drop the table if it already exists, for the same reason as above.
DROP TABLE IF EXISTS zepto;

-- Create the table that will hold the imported CSV data.
-- Each column is given an explicit type up front (prices as DECIMAL,
-- counts as INT, text as VARCHAR) so later calculations and sorts
-- behave correctly.

CREATE TABLE zepto(
    sku_id INT PRIMARY KEY AUTO_INCREMENT,     -- SKU: Stock Keeping Unit, unique per product
    category VARCHAR(150),
    name VARCHAR(200) NOT NULL,
    mrp DECIMAL(10,2),
    discountPercent INT,
    availableQuantity INT,
    discountedSellingPrice DECIMAL(10,2),
    weightInGms INT,
    outOfStock text,                            -- stock status, arrives as 'TRUE'/'FALSE' text
    quantity INT
);
set @@autocommit = 1 ;

-- ============================================================
-- STEP 2: DATA IMPORT
-- Goal: Load the CSV into the table, then verify the import
--       worked before relying on the data for anything else.
-- ============================================================

-- Import zepto_v.csv into the zepto table using your preferred
-- MySQL import method (Table Data Import Wizard, LOAD DATA, etc.).

-- Quick look at a sample of the imported rows.
select * from zepto;

-- Confirm every column landed with the correct type and constraints.
Describe Zepto;

-- ============================================================
-- STEP 3: DATA TYPE CORRECTION (outOfStock)
-- Goal: Fix a common real-world import issue — MySQL will not
--       auto-convert the text 'TRUE'/'FALSE' into a true BOOLEAN.
-- Note: This step isn't needed for every project — only when a
--       column's raw values don't match its intended data type.
-- ============================================================

-- Temporarily disable safe-update mode so the UPDATE below can run.
-- 0 = off, 1 = on. 
set @@sql_safe_updates = 0;



-- Convert the text values into their numeric BOOLEAN equivalents:
-- 'TRUE' -> 1, 'FALSE' -> 0.
update zepto 
set outOfStock = case
	when upper(outOfStock) = "TRUE" then "1"
	when upper(outOfStock) = "FALSE" Then "0"
	else outOfStock
end ;

-- Check the values after the conversion.
select * from zepto;

-- Only now that the values are numeric, change the column's
-- data type from TEXT to BOOLEAN.
alter table zepto modify outOfStock boolean ;

-- Confirm the column type change took effect.
select * from zepto;


-- ============================================================
-- STEP 4: DATA EXPLORATION
-- Goal: Understand what the data actually contains before
--       drawing any business conclusions from it.
-- ============================================================

-- Sample of the data after cleanup so far.
select * from zepto;

-- How many products are in stock vs out of stock?
select outOfStock , count(*) from zepto
group by outOfStock;

-- Result: 0 (in stock)     -> 3275
--         1 (out of stock) -> 453


-- Check every column for missing (NULL) values.
select * from Zepto
where category is null 
or 
name is null 
or 
mrp is null 
or 
discountPercent is null 
or 
availableQuantity is null 
or 
discountedSellingPrice is null 
or 
weightInGms is null 
or 
outOfStock is null 
or 
quantity is null ;

-- Result: no missing values in any column.

-- What product categories exist in the catalogue?

select distinct category  from zepto;

/* Result:
Fruits & Vegetables
Cooking Essentials
Munchies
Dairy, Bread & Batter
Beverages
Packaged Food
Ice Cream & Desserts
Chocolates & Candies
Meats, Fish & Eggs
Biscuits
Personal Care
Paan Corner
Home & Cleaning
Health & Hygiene
*/

-- Repeat of the in-stock / out-of-stock split, with a clearer alias.
select outOfStock , count(sku_id) as stock_count from zepto
group by outOfStock;

-- Result: 0 -> 3275, 1 -> 453

-- Which product names appear more than once? (Often different
-- pack sizes or SKUs listed under the same name.)
select distinct name , count(sku_id) as product_count from zepto
group by name 
having count(sku_id) > 1
order by count(sku_id) desc;  


-- ============================================================
-- STEP 5: DATA CLEANING
-- Goal: Remove invalid rows and normalise the currency values
--       before any revenue or pricing math is calculated.
-- ============================================================

-- A. Find products where the price or selling price is ₹0.
-- Reason: a real product can never be sold at ₹0 — these rows are
-- mistakes from the data export, not genuine listings.

select * from zepto 
where mrp = 0 
or 
discountedsellingPrice = 0;
 
 -- B. Remove those invalid rows so they don't distort later analysis.
delete from zepto 
where mrp = 0 
or 
discountedsellingPrice = 0;

-- C. Convert prices from paise into rupees.
-- The raw export stores currency in paise (1 rupee = 100 paise),
-- a common convention in financial data exports.
update zepto 
set mrp = mrp/100.0,
discountedsellingPrice = discountedsellingPrice/100.0; 


-- Confirm prices are now in normal, readable rupee amounts.
select mrp, discountedsellingPrice from zepto ;


-- ============================================================
-- STEP 6: BUSINESS ANALYSIS QUERIES
-- Goal: Turn the clean table into answers for real questions
--       that different Zepto business teams would actually ask.
-- ============================================================


-- Q1. Find the top 10 best-value products based on the discount percentage.
-- Business use: powers a "Best Deals" banner on the app home screen.
-- Solution: 
select distinct name , mrp, discountPercent 
from Zepto 
order by discountPercent desc
limit 10;


-- Q2.What are the Products with High MRP but Out of Stock.
-- Business use: a restocking alert for the inventory/supply-chain team,
-- since expensive items going out of stock means lost revenue.
-- Solution:
select distinct name, mrp 
from zepto
where outOfStock = true 
and mrp > 300
order by mrp desc;

-- Q3.Calculate Estimated Revenue for each category.
-- Business use: helps category managers decide where to invest
-- ad spend and warehouse space.
-- solution:
select category, sum(discountedSellingPrice * availableQuantity) as total_revenue
from zepto
group by category
order by total_revenue ; 

-- Q4. Find all products where MRP is greater than ₹500 and discount is less than 10%.
-- Business use: a pricing-team review list — strong candidates for
-- a promotional push to boost conversion.
-- Solution:
select name , mrp, discountPercent 
from zepto
where mrp > 500 
and 
discountPercent < 10 
order by mrp desc , discountPercent desc;

-- Q5. Identify the top 5 categories offering the highest average discount percentage.
-- Business use: tells marketing which categories already look
-- generous enough to headline a discount campaign.
-- Solution: 
select distinct category, 
		avg(discountPercent) as avg_discountPercent 
from zepto 
group by category
order by avg_discountPercent desc
limit 5 ;

-- Q6. Find the price per gram for products above 100g and sort by best value.
-- Business use: powers a "cheapest per gram" sort/filter for
-- price-conscious shoppers, since pack size can hide true value.
-- Solution: 
select distinct name, mrp, weightInGms,
Round((mrp/weightInGms),2) as price_per_gms 
from zepto
where weightInGms >= 100
order by price_per_gms desc;


-- Q7.Group the products into categories like Low, Medium, Bulk.
-- Business use: logistics uses this to decide packaging and
-- delivery-slot handling, since bulk items need different handling.
-- Solution: 
select name , weightInGms , 
case 
	when weightInGms < 1000 then "Low"
    When weightInGms < 5000 then "Medium"
    else "Bulk" 
end as weight_Category
from zepto ;


-- Q8.What is the Total Inventory Weight Per Category.
-- Business use: informs warehouse planning — heavier categories
-- need more shelf space and cold-storage capacity.
-- Solution:
select category, 
sum(weightInGms * availableQuantity) as weight_category
from zepto
group by category 
order by weight_category desc; 


-- ============================================================
-- STEP 7: ADVANCED ANALYSIS — CTE + CORRELATED SUBQUERIES
-- Goal: Compare each product against its own category's benchmark,
--       using a CTE to pre-compute the benchmark and a correlated
--       subquery in the WHERE clause to compare row-by-row.
-- ============================================================

-- Q9. Products priced above their own category's average MRP.
-- Business use: helps the pricing team spot products that stand out
-- as expensive within their category, worth a pricing review.

-- Solution: 
with avg_mrp as (
	select category, 
			round(avg(mrp),2) as average_mrp
	from zepto 
	group by category
)
select z.name , z.category, z.mrp
from zepto z
where z.mrp > (
		select a.average_mrp 
        from avg_mrp a
        where a.category = z.category
)
order by z.category asc ,z.mrp desc;


-- Q10. Out-of-stock products priced above their category's average selling price.
-- Business use: a restocking priority list — these products earn
-- more than most others in their category, so being out of stock
-- costs the business more than an average item would.

-- solution: 
with category_price as (
	select category , 
			round(avg(discountedSellingPrice),2) as avg_selling_price
	from zepto 
	where outOfStock = True
	group by category 
)

select z.name , z.category, z.discountedSellingPrice 
from zepto z
where outofStock = True
and 
z.discountedSellingPrice > (
					select cp.avg_selling_price 
                    from category_price cp 
                    where cp.category = z.category 
                    )
order by z.category, z.discountedSellingPrice desc;


-- Q11. The single highest-revenue product within each category.
-- Business use: tells category managers exactly which product to
-- protect from running out of stock — it's the top revenue driver.
-- solution: 
with category_revenue as (
	select sku_id ,category, name ,
			(discountedSellingPrice * availableQuantity) as revenue
	from zepto 
)

select c.name, c.category, c.revenue 
from category_revenue c
where c.revenue = (
		select max(cr.revenue) 
        from category_revenue cr
        where cr.category = c.category 
        )
order by c.revenue desc;

-- Q12. Products cheaper per gram than the category's average price-per-gram.
-- Business use: powers a "best value" filter for budget-conscious
-- shoppers and helps marketing highlight genuinely good deals.
-- Solution:
with ppg as (
	select sku_id , category, name ,
			round(mrp/ weightInGms, 2) as price_per_gms
	from zepto
),
category_ppg as (
	select category , 
			round(avg(price_per_gms),2) as avg_ppg
    from ppg    
    group by category
)

select p.name , p.category , p.price_per_gms 
from ppg p
where p.price_per_gms < (
			select c.avg_ppg 
            from category_ppg c
            where c.category = p.category
            )
order by p.category, p.price_per_gms asc;

