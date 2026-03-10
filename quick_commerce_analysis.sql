/*These are the main Features/Columns available in the dataset :
1) Order_ID: Unique identifier for each order.
2) Company: Name of the quick commerce platform (e.g., Blinkit, Zepto, Swiggy Instamart, etc.).
3) City: City where the order was placed.
4) Customer_Age: Age of the customer who placed the order.
5) Order_Value: Total monetary value of the order.
6) Delivery_Time_Min: Time taken to deliver the order (in minutes).
7) Distance_KM: Distance between the store and the customer (in kilometers).
8) Items_Count: Number of items included in the order.
9) Product_Category: Product category of the ordered item.
10) Payment Method : Payment done by Card, Wallet, Cash etc
11) Customer_Rating: Rating given by the customer on a scale of 1 to 5.
12) Discount_Applied: Discount applied to the order or not.
13) Delivery_Partner_Rating: Rating given to the delivery partner on a scale of 1 to 5.*/

-- ===========================
-- CREATE DATABASE AND TABLE
-- ===========================
CREATE DATABASE Q_Commerce;
use Q_Commerce;

CREATE TABLE order_details (
    Order_Id BIGINT,
    Company VARCHAR(50),
    City VARCHAR(50),
    Customer_Age INT NULL,
    Order_Value DECIMAL(10,2) NULL,
    Delivery_Time_Min INT NULL,
    Distance_KM DECIMAL(5,2) NULL,
    Items_Count INT NULL,
    Product_Category VARCHAR(100),
    Payment_Method VARCHAR(25),
    Customer_Rating DECIMAL(3,1) NULL,
    Discount_Applied TINYINT NULL,
    Delivery_Partner_Rating DECIMAL(3,1) NULL
);
-- ==============
-- LOAD DATA
-- ==============

SHOW VARIABLES LIKE 'secure_file_priv'; # Check secure file directory.MySQL allows bulk file loading ONLY from this folder
                                        # Bulk load CSV data into MySQL table. LOAD DATA INFILE is the fastest way to insert large CSV files
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/quick_commerce_data_raw.csv'
IGNORE # If MySQL finds bad data in some rows, it will skip those rows.instead of stopping the entire load
INTO TABLE order_details
FIELDS TERMINATED BY ',' #CSV format rules. Columns are separated by commas
ENCLOSED BY '"' #Text values are enclosed within double quotes
LINES TERMINATED BY '\n' #Each new line in the file represents a new row
IGNORE 1 ROWS   # Ignore the first row because it contains column names
(
    Order_Id,     #Column mapping section
    Company,
    City,
    @Customer_Age,   #Columns with @ are temporary variables .They are used when data may be dirty (empty spaces, blanks, etc.)
    @Order_Value,
    @Delivery_Time_Min,
    @Distance_KM,
    @Items_Count,
    Product_Category,
    Payment_Method,
    @Customer_Rating,
    @Discount_Applied,
    @Delivery_Partner_Rating
)
SET  # SET clause is used for data cleaning before inserting into table.TRIM removes extra spaces.NULLIF converts empty values ('') to NULL
 Customer_Age = NULLIF(TRIM(@Customer_Age), ''),
 Order_Value = NULLIF(TRIM(@Order_Value), ''),
 Delivery_Time_Min = NULLIF(TRIM(@Delivery_Time_Min), ''),
 Distance_KM = NULLIF(TRIM(@Distance_KM), ''),
 Items_Count = NULLIF(TRIM(@Items_Count), ''),
 Customer_Rating = NULLIF(TRIM(@Customer_Rating), ''),
 Discount_Applied = NULLIF(TRIM(@Discount_Applied), ''),
 Delivery_Partner_Rating = NULLIF(TRIM(@Delivery_Partner_Rating), '');

select * from order_details;
-- ===============
-- DATA CLEANING : Data cleaning involves understanding the data, handling missing values, removing duplicates, fixing invalid records,handling outliers
--                 trimming and standardizing categorical variables, validating ranges, correcting data types, and performing final validation.
-- ===============
DESCRIBE order_details; -- COLUMN NAME,TYPE & TELLS NULL PRESENT OR NOT

-- TRIM TEXT DATA : To ignore extra spaces
UPDATE order_details
SET company= trim(company),
	city = trim(city),
    product_category = trim(product_category),
    payment_method = trim(payment_method);
    
-- Check Data Size & Structure
SELECT count(*) FROM order_details; #Data has '1000000' rows

-- Check duplicates
SELECT order_id,count(*) FROM order_details  GROUP BY order_id HAVING count(*) > 1; # No duplcate rows present

-- count null values
SELECT 
sum(order_id is null) as order_id_null_count,
sum(company is null) as company_null_count,
sum(city is null) as city_null_count,
sum(customer_age is null) as customer_age_null_count,
sum(Order_Value is null) as Order_Value_null_count,
sum(Delivery_Time_Min is null) as Delivery_Time_Min_null_count,
sum(Distance_KM is null) as Distance_KM_null_count,
sum(items_Count is null) as items_Count_null_count,
sum(Product_Category is null) as Product_Category_null_count,
sum(Payment_Method is null) as Payment_Method_null_count,
sum(Customer_Rating is null) as Customer_Rating_null_count,
sum(Discount_Applied is null) as Discount_Applied_null_count,
sum(Delivery_Partner_Rating is null) as Delivery_Partner_Rating_null_count FROM order_details;
-- Inference :After checking missing values, I found that only Items_Count(35000) and Customer_Rating(47000) had NULLs. 
--            I replaced missing item counts with 1 based on business logic and keep missing ratings as NULL since they indicate unrated orders.

UPDATE order_details SET items_count=1 WHERE items_count is null; 
-- Standardize missing city values
SELECT Distinct(city) FROM order_details;
UPDATE order_details SET city = null WHERE city is not null AND TRIM(city) = '';

-- Check min & max ranges
SELECT 'customer_age' as metric,min(customer_age) as min_value ,max(customer_age) as max_value FROM order_details
union all
SELECT 'Order_Value',min(Order_Value),max(Order_Value) FROM order_details
union all
SELECT 'Delivery_Time_Min',min(Delivery_Time_Min),max(Delivery_Time_Min) FROM order_details
union all
SELECT 'Distance_KM',min(Distance_KM),max(Distance_KM) FROM order_details
union all
SELECT 'items_Count',min(items_Count),max(items_Count) FROM order_details
union all
SELECT 'Customer_Rating',min(Customer_Rating),max(Customer_Rating) FROM order_details
union all
SELECT 'Delivery_Partner_Rating',min(Delivery_Partner_Rating),max(Delivery_Partner_Rating) FROM order_details;

-- Fix invalid ratings
UPDATE order_details set customer_rating= null WHERE customer_rating <0 or customer_rating> 5;
-- Inference:- No invalid customer ratings found outside 0–5 range
UPDATE order_details set Delivery_Partner_Rating= null WHERE Delivery_Partner_Rating <0 or Delivery_Partner_Rating> 5;
-- Inference:- No invalid Delivery Partner Rating found outside 0–5 range

-- Validate delivery time & distance 
DELETE FROM order_details WHERE Delivery_Time_Min <= 0 OR Delivery_Time_Min > 180;
DELETE FROM order_details WHERE Distance_KM <= 0 OR Distance_KM > 50;
SELECT * FROM ORDER_DETAILS LIMIT 10;

-- ===========================
-- PERFORMANCE OPTIMIZATION : Create indexes to improve query performance on frequently used columns
-- ===========================
CREATE INDEX idx_city ON order_details(city);

CREATE INDEX idx_company ON order_details(company);

CREATE INDEX idx_product_category ON order_details(product_category);

CREATE INDEX idx_payment_method ON order_details(payment_method);

-- ============
-- KPI SUMMARY : KPI = Key Performance Indicator , a metric that measures how well a business is performing.
-- ============
SELECT count(order_id) as total_orders,
round(sum(order_value),2) as total_revenue,
round(avg(order_value),2) as avg_order_value,
round(avg(delivery_time_min),2) as avg_delivery_time,
round(avg(customer_rating),2) as avg_customer_rating FROM order_details; 
-- INFERENCE : 
# The platform processed 1 million orders, generating approximately ₹57.16 crore in total revenue. 
# The average order value is around ₹572.
# The average delivery time is about 16.5 minutes, indicating strong operational efficiency. 
# The average customer rating of 3.04 suggests moderate customer satisfaction.

-- Business Insight : The platform maintains fast delivery speeds and high order volumes, which are key strengths in the quick-commerce market.
--                   However, the moderate customer rating indicates room for improvement in service quality, such as delivery experience, product availability, or order accuracy.

-- ===========================
-- BUSINESS & SALES ANALYSIS
-- ==========================
#1  What is the total revenue generated?
SELECT sum(order_value) as total_revenue FROM order_details; 
-- Inference :- The platform made around ₹57.1 crore in total revenue. This shows that the business handles a large number of orders.
-- Business Insight: Since the revenue is already good, the company can try to earn more from existing customers by improving prices, 
--                    giving useful discounts, and suggesting related products.

#2 What is the average order value?
SELECT avg(order_value) as avg_order_value FROM order_details;  
-- Inference :- On average, customers spend about ₹572 per order.
--  Business Insight: This is normal for grocery and quick delivery apps. The company can increase the bill size by offering combo deals, 
--                    free delivery above a certain amount, and product suggestions based on past orders.

#3 Which city generates the highest revenue?
SELECT city,sum(order_value) as revenue FROM order_details GROUP BY city ORDER BY revenue desc; -- 'Gurgaon', '54963778.01'
-- Inference :- Gurgaon brings the highest revenue.
-- Business Insight: Customers in Gurgaon usually spend more per order, so the company can focus on premium products and loyalty offers in this city.ts

#4 Top 5 cities by revenue
SELECT city,sum(order_value) AS revenue FROM order_details GROUP BY city ORDER BY revenue DESC LIMIT 5;
-- Inference : The top revenue-generating cities are Gurgaon, Noida, Delhi, Mumbai, and Bengaluru.
-- Business Insight : These cities contribute a large portion of total revenue and may represent strong demand centers for quick commerce services.

#5 Which city has the highest number of orders?
SELECT city,count(order_id) as no_of_orders  FROM order_details WHERE city is not null GROUP BY city ORDER BY no_of_orders desc; -- 'Hyderabad', '79481'
-- Inference: Hyderabad has the highest number of orders, which means people order frequently here.
-- Business Insight: Since Hyderabad is a high-order city, the focus should be on fast delivery, good stock availability, 
--                   and smooth operations rather than pushing expensive products.

#6 What is the average order value by city?
SELECT city,avg(order_value) as avg_order_val FROM order_details WHERE city is not null GROUP BY city;
-- Inference:
--    Gurgaon and Noida have higher order values
--    Haridwar and Jaipur have lower order values
--    Hyderabad has a medium order value even though it has the most orders
-- Business Insight: Some cities place many small orders, while others place fewer but bigger orders. Each city needs a different business approach.

#7 Which company receives the most orders?
SELECT company, count(order_id) as no_of_orders FROM order_details GROUP BY company ORDER BY no_of_orders desc; -- Flipkart Minutes	125542
-- Inference: Flipkart Minutes gets the most orders.
-- Business Insight: This shows that many customers use the platform often, possibly because of discounts and affordable pricing
 
#8 Which company generates the highest revenue?
SELECT company,sum(order_value) as revenue FROM order_details GROUP BY company ORDER BY revenue desc; 
-- Inference: Swiggy Instamart earns the most revenue.
-- Business Insight: Even with fewer orders, customers tend to spend more per order, which increases total revenue.

#9 What is the average order value per company?
SELECT company,avg(order_value) as avg_order_val FROM order_details GROUP BY company ;
-- Inference:
-- Swiggy Instamart and Blinkit have higher order values
-- Jio Mart has lower order values
-- Business Insight: Some companies focus on convenience and premium customers, while others focus on lower prices and mass customers.

-- ===============================
-- DELIVERY PERFORMANCE ANALYSIS 
-- ===============================
#10 What is the average delivery time overall?
SELECT avg(delivery_time_min) FROM order_details; 
-- Inference : The average delivery time across all orders is 16.46 minutes.
-- Business Insight : Maintaining delivery times under 20 minutes is important for quick-commerce platforms. 
--                    Fast delivery improves customer satisfaction and increases the chances of repeat orders.

#11 Which city has the fastest average delivery time?
SELECT city,avg(delivery_time_min) as avg_time FROM order_details GROUP BY city ORDER BY avg_time asc; 
-- Inference : Delhi has the fastest average delivery time(7.14)  among all cities.
-- Business Insight: This could indicate better logistics infrastructure, shorter delivery distances, or higher availability of delivery partners in Delhi.

#12 Which city has the slowest average delivery time?
SELECT city,avg(delivery_time_min) as avg_time FROM order_details GROUP BY city ORDER BY avg_time DESC limit 1;
 -- Inference : Haridwar has the slowest average delivery time(27.5 min).
--  Business Insight : This may be due to longer delivery distances, lower order density, or fewer delivery partners in the area.

#13 What is the average delivery time by company?
SELECT company,avg(delivery_time_min) as avg_time FROM order_details GROUP BY company ORDER BY avg_time asc;
-- Inference : Zepto has the fastest delivery (~9.6 min), while Jio Mart has the slowest (~23 min).
-- Business Insight : Companies with faster deliveries can gain a competitive advantage in the quick-commerce market where speed is a major differentiator.

#14 What percentage of orders are delivered within 30 minutes?
SELECT round(sum(case when Delivery_Time_Min <= 30 then 1 else 0 end) * 100.0 / COUNT(*),2) as pct_orders_delivered FROM order_details; 
-- Inference : Around 97.75% of orders are delivered within 30 minutes.
-- Business Insight : This indicates strong last-mile logistics performance, which is essential for maintaining customer satisfaction.

#15 Relationship between delivery distance and delivery time
SELECT ROUND(AVG(distance_km),2) AS avg_distance, ROUND(AVG(delivery_time_min),2) AS avg_delivery_time FROM order_details; 
-- Inference: The average delivery distance is 7.75 km, and the average delivery time is 16.46 minutes, showing that most orders are delivered within a reasonable time despite moderate distances.
-- Business Insight: This suggests efficient delivery operations and good route management, which helps maintain fast deliveries and better customer satisfaction.

-- =============================
-- CUSTOMER & RATING ANALYSIS
-- ============================
#16 What is the average customer rating overall?
SELECT Round(avg(Customer_Rating),1) FROM order_details; 
-- Inference : The overall average customer rating is 3.0.
-- Business Insight : A rating around 3 indicates moderate customer satisfaction, suggesting that service quality can still be improved.

#17 What is the average customer rating by city?
SELECT city,Round(avg(Customer_Rating),1) as avg_rating FROM order_details WHERE city is not null GROUP BY city;
-- Inference: Bengaluru shows the highest customer rating (~3.5) while Hyderabad has the lowest customer rating (~2.5).
-- Business Insight : Lower ratings in some cities may indicate delivery delays, product quality issues, or poor service experience.

#18 What is the average customer rating by company?
SELECT company,Round(avg(Customer_Rating),1) as avg_rating FROM order_details GROUP BY company ORDER BY avg_rating desc;
-- Inference : Blinkit has the highest average rating (~3.6).
-- Business Insight : Higher ratings may reflect better service quality, faster deliveries, or more reliable operations.

#19 Which company has the highest average customer rating?
SELECT company,Round(avg(Customer_Rating),1) as avg_rating FROM order_details GROUP BY company ORDER BY avg_rating desc limit 1; -- Blinkit	3.6
-- Inference : Blinkit has the highest customer satisfaction among the companies.
-- Business Insight : High customer ratings can lead to strong brand loyalty and higher repeat order rates.

#20 What percentage of orders are not rated by customers?
SELECT round(sum(case when Customer_Rating is null then 1 else 0 end)* 100 /count(*),2) as pct_not_rated FROM order_details; -- '4.7000'
-- Inference : Only a small fraction of orders are not rated by customers.
-- Business Insight : High rating participation suggests customers are actively giving feedback,
--                    which helps companies monitor service quality and improve operations.

#21 Which age group places the most orders?
SELECT case
when Customer_Age between 18 and 25 then '18-25'
when Customer_Age between 26 and 35 then '26-35'
when Customer_Age between 36 and 45 then '36-45'
when Customer_Age between 46 and 60 then '46-60'
else '60+' end as age_group,
COUNT(*) AS total_orders FROM order_details GROUP BY age_group ORDER BY total_orders DESC;

-- Inference: Customers in the 46–60 age group place the highest number of orders (332,000), 
--           followed by the 26–35 and 36–45 age groups, while the 18–25 group places the fewest orders.
-- Business Insight: This suggests that middle-aged and older customers are the most active users of quick-commerce services, possibly due to higher purchasing power and regular household needs.
--                     Companies can target this segment with loyalty programs, subscription plans, and essential product bundles, while using discounts or 
--                     marketing campaigns to increase engagement among younger customers.

-- ============================
-- DISCOUNT & PRICING ANALYSIS
-- ============================
#22 What percentage of orders had discounts applied?
SELECT round(sum(case when Discount_Applied=1 then 1 else 0 end)* 100/count(*),2) as pct_orders_dis_applied FROM order_details; -- # pct_orders_dis_applied '40.09'
-- Inference : A significant portion of orders involve discounts or promotional offers.
-- Business Insight : Discounts play an important role in attracting customers and increasing order volume, 
--                    but excessive discounting may reduce profit margins.

#23 What is the average order value for discounted vs non-discounted orders?
SELECT case 
           when Discount_Applied=1 then 'Discount_applied'
           Else 'No_Discount' end as discount_status,
           round(avg(Order_Value),2)  as avg_order_value FROM order_details
GROUP BY Discount_Applied;
-- Inference : Orders with discounts have higher average order value.
-- Business Insight : Discounts encourage customers to add more items to their cart, increasing basket size and total spending.

#24 Which company uses discounts the most?
SELECT company,
COUNT(CASE WHEN Discount_Applied=1 THEN 1 END) AS discounted_orders,
COUNT(*) AS total_orders,
ROUND(COUNT(CASE WHEN Discount_Applied=1 THEN 1 END)*100.0/COUNT(*),2) AS discount_pct
FROM order_details
GROUP BY company
ORDER BY discount_pct DESC;
-- Inference : Blinkit uses discounts slightly more frequently compared to other companies.
-- Business Insight : Frequent discounts may help Blinkit attract more customers and increase order volume, especially in competitive markets.

#25 Do discounted orders have higher or lower customer ratings?
SELECT case
      when Discount_Applied=1 then 'Discounted'
      else 'No_Discount' end as discount_status,
avg(Customer_Rating) FROM order_details GROUP BY Discount_Applied;
-- Inference : Customer ratings are almost the same for discounted and non-discounted orders.
-- Business Insight : Discounts mainly influence purchase decisions rather than customer satisfaction.

-- =========================
-- ORDER BEHAVIOR ANALYSIS
-- =========================

#26 What is the average number of items per order?
SELECT round(AVG(Items_Count),0) FROM order_details; -- 10 items
-- Inference : On average, customers purchase around 10 items per order
-- Business Insight : A relatively large basket size increases the overall order value and revenue per order.

#27 Which product category is ordered the most?
SELECT Product_Category,sum(Items_Count) as item_count FROM order_details GROUP BY Product_Category ORDER BY item_count DESC limit 1; -- 'Dairy', '1395100'
-- Inference : Dairy is the most frequently ordered category.
-- Business Insight : Daily essentials like dairy products drive consistent demand in quick commerce platforms.

#28 Which product category generates the highest revenue?
SELECT Product_Category,sum(Order_Value) as revenue FROM order_details GROUP BY Product_Category ORDER BY revenue DESC limit 1;  -- 'Dairy', '82435517.00'
-- Inference : Dairy products also generate the highest revenue among all categories.
-- Business Insight : Essential categories such as dairy drive stable revenue streams for quick-commerce platforms.

#29 What is the average number of items per order by product category?
SELECT Product_Category,round(AVG(Items_Count),0) FROM order_details GROUP BY Product_Category;
-- Inference : Customers purchase a similar number of items regardless of product category.
-- Business Insight : Basket size appears consistent across categories, suggesting that customers tend to buy multiple products in one order.

#30 Which payment method is used most frequently?
SELECT payment_method,count(Payment_Method) as used_count FROM order_details GROUP BY Payment_Method ORDER BY used_count DESC limit 1; 
-- Inference : Cash on Delivery is the most commonly used payment method.
-- Business Insight : Many customers still prefer COD due to convenience or trust factors, even though digital payments are available.

-- ===========================
-- FINAL BUSINESS INSIGHTS
-- ===========================

-- Key Insights:

#1.Strong Revenue with High Order Volume :
-- The platform processed around 1 million orders, generating approximately ₹57 crore in total revenue with an average order value of about ₹572.
-- This indicates strong demand and large-scale operations in the quick-commerce market.

#2.Revenue and Order Volume Are Driven by Different Cities : Cities contribute differently to the business:
-- Gurgaon generates the highest revenue
-- Hyderabad has the highest number of orders
-- This shows that some cities are high-value markets, while others are high-volume markets, requiring different pricing and operational strategies.

#3.Delivery Operations Are Highly Efficient :
-- The average delivery time is about 16.5 minutes, and 97.75% of orders are delivered within 30 minutes.
--  This reflects strong logistics performance, which is a critical competitive advantage in quick-commerce services.

#4.Customer Satisfaction Is Moderate :
-- The average customer rating is around 3.0.
-- Suggesting that while operations are efficient, there is room to improve service quality, product availability, or delivery experience to increase customer satisfaction.

#5.Discounts Increase Order Value but Not Customer Satisfaction :
-- Around 40% of orders involve discounts, and discounted orders have a higher average order value. 
-- However, customer ratings are almost the same for discounted and non-discounted orders, indicating that discounts influence purchase behavior rather than satisfaction.

#6.Middle-Aged Customers Are the Most Active Users:
-- Customers aged 46–60 place the highest number of orders, showing that quick-commerce platforms are widely used by middle-aged consumers who likely purchase regular household essentials.

#7.Essential Products Drive the Business:
-- Dairy products are both the most ordered category and the highest revenue-generating category, confirming that essential daily items form the backbone of quick-commerce demand.

#8.Cash on Delivery Remains the Most Popular Payment Method
-- Despite the availability of digital payment options, Cash on Delivery is still the most frequently used payment method, indicating that many customers prefer the convenience or trust associated with COD.
select * from order_details
