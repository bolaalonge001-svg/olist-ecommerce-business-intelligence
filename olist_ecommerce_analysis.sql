-- =====================================================
-- E-COMMERCE BUSINESS INTELLIGENCE & CUSTOMER ANALYTICS
-- SQL ANALYSIS
-- =====================================================

USE olist_ecommerce;


-- =====================================================
-- 1. DATA VALIDATION
-- =====================================================
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM olist_customers_dataset

UNION ALL

SELECT 'orders', COUNT(*)
FROM olist_orders_dataset

UNION ALL

SELECT 'order_items', COUNT(*)
FROM olist_order_items_dataset

UNION ALL

SELECT 'products', COUNT(*)
FROM olist_products_dataset

UNION ALL

SELECT 'sellers', COUNT(*)
FROM olist_sellers_dataset

UNION ALL

SELECT 'payments', COUNT(*)
FROM olist_order_payments_dataset

UNION ALL

SELECT 'reviews', COUNT(*)
FROM olist_order_reviews_dataset

UNION ALL

SELECT 'categories', COUNT(*)
FROM product_category_name_translation

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM olist_geolocation_dataset;
-- =====================================================
-- 2. DUPLICATE & DATA QUALITY CHECKS
-- =====================================================
SELECT customer_id, COUNT(*)
FROM olist_customers_dataset
GROUP BY customer_id
HAVING COUNT(*) > 1;
SELECT customer_unique_id, COUNT(*)
FROM olist_customers_dataset
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;
SELECT order_id, COUNT(*)
FROM olist_orders_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;
SELECT order_id, COUNT(*)
FROM olist_order_items_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;
SELECT product_id, COUNT(*)
FROM olist_products_dataset
GROUP BY product_id
HAVING COUNT(*) > 1;
SELECT seller_id, COUNT(*)
FROM olist_sellers_dataset
GROUP BY seller_id
HAVING COUNT(*) > 1;
SELECT order_id, COUNT(*)
FROM olist_order_payments_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;
SELECT review_id, COUNT(*)
FROM olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*) > 1;
SELECT *
FROM olist_order_reviews_dataset
WHERE review_id = '00130cbe1f9d422698c812ed8ded1919';
SELECT
    SUM(YEAR(order_approved_at) = 0) AS missing_approved,
    SUM(YEAR(order_delivered_carrier_date) = 0) AS missing_carrier,
    SUM(YEAR(order_delivered_customer_date) = 0) AS missing_delivered
FROM olist_orders_dataset;
SELECT order_status, COUNT(*)
FROM olist_orders_dataset
GROUP BY order_status;
SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(YEAR(order_delivered_customer_date) = 0) AS missing_delivery_dates
FROM olist_orders_dataset
GROUP BY order_status;
SELECT COUNT(*) AS missing_category
FROM olist_products_dataset
WHERE product_category_name = '';
SELECT COUNT(*) AS missing_price
FROM olist_order_items_dataset
WHERE price IS NULL;
SELECT COUNT(*) AS missing_freight
FROM olist_order_items_dataset
WHERE freight_value IS NULL;
SELECT COUNT(*) AS missing_payment
FROM olist_order_payments_dataset
WHERE payment_value IS NULL;
SELECT COUNT(*) AS missing_review
FROM olist_order_reviews_dataset
WHERE review_score IS NULL;
SELECT COUNT(*) AS invalid_price
FROM olist_order_items_dataset
WHERE price <= 0;
SELECT COUNT(*) AS invalid_freight
FROM olist_order_items_dataset
WHERE freight_value < 0;
SELECT COUNT(*) AS invalid_payment
FROM olist_order_payments_dataset
WHERE payment_value <= 0;
SELECT COUNT(*) AS invalid_review_score
FROM olist_order_reviews_dataset
WHERE review_score < 1 OR review_score > 5;
SELECT COUNT(*) AS unmatched_orders
FROM olist_orders_dataset o
LEFT JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
SELECT COUNT(*) AS unmatched_order_items
FROM olist_order_items_dataset oi
LEFT JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
SELECT COUNT(*) AS unmatched_products
FROM olist_order_items_dataset o
LEFT JOIN olist_products_dataset p
    ON o.product_id = p.product_id
WHERE p.product_id IS NULL;
SELECT COUNT(*) AS unmatched_sellers
FROM olist_order_items_dataset oi
LEFT JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;
SELECT COUNT(*) AS unmatched_payments
FROM olist_order_payments_dataset p
LEFT JOIN olist_orders_dataset o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;
SELECT COUNT(*) AS unmatched_reviews
FROM olist_order_reviews_dataset r
LEFT JOIN olist_orders_dataset o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
-- =====================================================
-- 3. CORE BUSINESS KPIs
-- =====================================================
SELECT COUNT(*) AS total_orders
FROM olist_orders_dataset;
SELECT SUM(price) AS total_revenue
FROM olist_order_items_dataset;
SELECT AVG(order_total) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(price) AS order_total
    FROM olist_order_items_dataset
    GROUP BY order_id
) AS order_totals;
SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_dataset;
SELECT
    customer_unique_id,
    COUNT(*) AS number_of_orders
FROM olist_customers_dataset
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;
SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT
        customer_unique_id,count(*)
    FROM olist_customers_dataset
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) AS repeat_customers;
SELECT 
    ROUND(
        COUNT(CASE WHEN number_of_orders > 1 THEN 1 END) 
        / COUNT(*) * 100, 
        2
    ) AS repeat_customer_rate
FROM (
    SELECT
        customer_unique_id,
        COUNT(*) AS number_of_orders
    FROM olist_customers_dataset
    GROUP BY customer_unique_id
) AS customer_orders;
-- =====================================================
-- 4. SALES & REVENUE ANALYSIS
-- =====================================================
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY month;
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        ROUND(SUM(oi.price), 2) AS monthly_revenue
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),

sales_with_previous AS (
    SELECT
        month,
        monthly_revenue,
        LAG(monthly_revenue) OVER(ORDER BY month) AS previous_month_revenue
    FROM monthly_sales
)

SELECT
    month,
    monthly_revenue,
    previous_month_revenue,
    ROUND(
        (monthly_revenue - previous_month_revenue)
        / previous_month_revenue * 100,
        2
    ) AS growth_percent
FROM sales_with_previous;
-- =====================================================
-- 5. PRODUCT & CATEGORY ANALYSIS
-- =====================================================
SELECT
    t.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY total_revenue DESC;
SELECT
    COALESCE(t.product_category_name_english, 'Unknown') AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english, 'Unknown')
ORDER BY items_sold DESC;
SELECT
    COALESCE(t.product_category_name_english, 'Unknown') AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english, 'Unknown')
ORDER BY total_revenue DESC;
-- =====================================================
-- 6. GEOGRAPHIC ANALYSIS
-- =====================================================
SELECT
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;
WITH order_totals AS (
    SELECT
        o.order_id,
        c.customer_state AS state,
        SUM(oi.price) AS order_total
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, c.customer_state
)

SELECT
    state,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_total), 2) AS average_order_value
FROM order_totals
GROUP BY state
ORDER BY average_order_value DESC;
-- =====================================================
-- 7. DELIVERY & CUSTOMER SATISFACTION ANALYSIS
-- =====================================================
SELECT
    ROUND(
        AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),
        2
    ) AS average_delivery_days
FROM olist_orders_dataset
WHERE YEAR(order_delivered_customer_date) > 0;
SELECT
    COUNT(*) AS late_deliveries
FROM olist_orders_dataset
WHERE YEAR(order_delivered_customer_date) > 0
  AND order_delivered_customer_date > order_estimated_delivery_date;
  SELECT
    ROUND(
        SUM(order_delivered_customer_date > order_estimated_delivery_date)
        / COUNT(*) * 100,
        2
    ) AS late_delivery_rate
FROM olist_orders_dataset
WHERE YEAR(order_delivered_customer_date) > 0;
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    COUNT(*) AS total_reviews,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM olist_orders_dataset o
JOIN olist_order_reviews_dataset r
    ON o.order_id = r.order_id
WHERE YEAR(o.order_delivered_customer_date) > 0
GROUP BY delivery_status;
-- =====================================================
-- 8. SELLER PERFORMANCE ANALYSIS
-- =====================================================
SELECT
    seller_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(
        SUM(price) / COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY total_revenue DESC
LIMIT 10;
SELECT
    seller_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(
        SUM(price) / COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY total_revenue DESC
LIMIT 10;
SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM olist_order_items_dataset oi
JOIN olist_order_reviews_dataset r
    ON oi.order_id = r.order_id
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;
-- =====================================================
-- 9. PAYMENT ANALYSIS
-- =====================================================
SELECT
    payment_type,
    COUNT(*) AS number_of_payments,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY number_of_payments DESC;
SELECT
    payment_installments,
    COUNT(*) AS number_of_payments
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY number_of_payments DESC;
SELECT
    payment_installments,
    COUNT(*) AS number_of_payments,
    ROUND(AVG(payment_value), 2) AS average_payment_value
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;
-- =====================================================
-- 10. ADVANCED SQL ANALYSIS
-- =====================================================

    WITH state_category_revenue AS (
    SELECT
        c.customer_state AS state,
        COALESCE(t.product_category_name_english, 'Unknown') AS category,
        SUM(oi.price) AS total_revenue
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    JOIN olist_products_dataset p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name
    GROUP BY
        c.customer_state,
        COALESCE(t.product_category_name_english, 'Unknown')
)

SELECT
    state,
    category,
    ROUND(total_revenue, 2) AS total_revenue,
    RANK() OVER(
        PARTITION BY state
        ORDER BY total_revenue DESC
    ) AS category_rank
FROM state_category_revenue;
WITH state_category_revenue AS (
    SELECT
        c.customer_state AS state,
        COALESCE(t.product_category_name_english, 'Unknown') AS category,
        SUM(oi.price) AS total_revenue
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    JOIN olist_products_dataset p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name
    GROUP BY
        c.customer_state,
        COALESCE(t.product_category_name_english, 'Unknown')
),

ranked_categories AS (
    SELECT
        state,
        category,
        total_revenue,
        RANK() OVER(
            PARTITION BY state
            ORDER BY total_revenue DESC
        ) AS category_rank
    FROM state_category_revenue
)

SELECT
    state,
    category,
    ROUND(total_revenue, 2) AS total_revenue
FROM ranked_categories
WHERE category_rank = 1
ORDER BY state;
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        SUM(oi.price) AS monthly_revenue
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)

SELECT
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(monthly_revenue) OVER(ORDER BY month),
        2
    ) AS cumulative_revenue
FROM monthly_sales
ORDER BY month;
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        SUM(oi.price) AS monthly_revenue
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)

SELECT
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(
        AVG(monthly_revenue) OVER(
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS three_month_moving_average
FROM monthly_sales
ORDER BY month;
-- =====================================================
-- 11. CUSTOMER ANALYSIS
-- =====================================================
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_spent
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_spent
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY total_spent DESC
LIMIT 10;
WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS total_spent
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    ROUND(total_spent, 2) AS total_spent,
    CASE
        WHEN total_spent >= 1000 THEN 'High Value'
        WHEN total_spent >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_spending
ORDER BY total_spent DESC;
WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS total_spent
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),

customer_segments AS (
    SELECT
        customer_unique_id,
        total_spent,
        CASE
            WHEN total_spent >= 1000 THEN 'High Value'
            WHEN total_spent >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer_spending
)

SELECT
    customer_segment,
    COUNT(*) AS number_of_customers,
    ROUND(SUM(total_spent), 2) AS total_revenue
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_revenue DESC;
SELECT MAX(order_purchase_timestamp) AS latest_order_date
FROM olist_orders_dataset;
-- =====================================================
-- 12. RFM CUSTOMER SEGMENTATION
-- =====================================================

WITH rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(
            '2018-10-17',
            MAX(o.order_purchase_timestamp)
        ) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price), 2) AS monetary
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    NTILE(4) OVER(ORDER BY recency DESC) AS recency_score
FROM rfm;

WITH rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(
            '2018-10-17',
            MAX(o.order_purchase_timestamp)
        ) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price), 2) AS monetary
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,

        NTILE(4) OVER(ORDER BY recency DESC) AS recency_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            ELSE 4
        END AS frequency_score,

        NTILE(4) OVER(ORDER BY monetary) AS monetary_score
    FROM rfm
)

SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,

    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_score

FROM rfm_scores;
WITH rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(
            '2018-10-17',
            MAX(o.order_purchase_timestamp)
        ) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price), 2) AS monetary
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        NTILE(4) OVER(ORDER BY recency DESC) AS recency_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            ELSE 4
        END AS frequency_score,

        NTILE(4) OVER(ORDER BY monetary) AS monetary_score
    FROM rfm
)

SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,

    CASE
        WHEN recency_score = 4
             AND frequency_score >= 2
             AND monetary_score >= 3
            THEN 'Best Customers'

        WHEN frequency_score >= 2
            THEN 'Loyal Customers'

        WHEN recency_score >= 3
             AND frequency_score = 1
            THEN 'Recent Customers'

        WHEN recency_score <= 2
             AND monetary_score >= 3
            THEN 'At Risk'

        ELSE 'Low Engagement'
    END AS customer_segment

FROM rfm_scores;
WITH rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(
            '2018-10-17',
            MAX(o.order_purchase_timestamp)
        ) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT
        *,
        NTILE(4) OVER(ORDER BY recency DESC) AS recency_score,
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            ELSE 4
        END AS frequency_score,
        NTILE(4) OVER(ORDER BY monetary) AS monetary_score
    FROM rfm
),

segments AS (
    SELECT
        *,
        CASE
            WHEN recency_score = 4
                 AND frequency_score >= 2
                 AND monetary_score >= 3
                THEN 'Best Customers'
            WHEN frequency_score >= 2
                THEN 'Loyal Customers'
            WHEN recency_score >= 3
                 AND frequency_score = 1
                THEN 'Recent Customers'
            WHEN recency_score <= 2
                 AND monetary_score >= 3
                THEN 'At Risk'
            ELSE 'Low Engagement'
        END AS customer_segment
    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS number_of_customers,
    ROUND(SUM(monetary), 2) AS total_revenue
FROM segments
GROUP BY customer_segment
ORDER BY number_of_customers DESC;
-- =====================================================
-- 13. ORDER STATUS ANALYSIS
-- =====================================================
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM olist_orders_dataset),
        2
    ) AS percentage_of_orders
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY total_orders DESC;
-- =====================================================
-- 14. REVIEW SCORE DISTRIBUTION
-- =====================================================

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM olist_order_reviews_dataset),
        2
    ) AS percentage_of_reviews
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;

-- =====================================================
-- END OF ANALYSIS
-- =====================================================



