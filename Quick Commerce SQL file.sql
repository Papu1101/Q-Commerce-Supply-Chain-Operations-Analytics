CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    brand VARCHAR(100),
    mrp NUMERIC(10,2),
    selling_price NUMERIC(10,2),
    discount_percent NUMERIC(5,2),
    unit VARCHAR(50),
    in_stock BOOLEAN,
    stock_quantity INTEGER,
    expiry_date DATE,
    rating NUMERIC(3,2),
    review_count INTEGER,
    is_veg BOOLEAN,
    added_date DATE
);

select * from products;

----Stores----

CREATE TABLE stores (
    store_id VARCHAR(50) PRIMARY KEY,
    store_name VARCHAR(255),
    city VARCHAR(100),
    zone VARCHAR(100),
    pincode VARCHAR(20),
    store_type VARCHAR(100),
    opening_date DATE,
    operating_hours VARCHAR(100),
    manager_name VARCHAR(150),
    contact_number VARCHAR(30),
    latitude NUMERIC(10,6),
    longitude NUMERIC(10,6),
    status VARCHAR(50),
    daily_order_capacity INTEGER
);


select * from stores;

--Customers---

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone_number VARCHAR(30),
    city VARCHAR(100),
    pincode VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(30),
    registration_date DATE,
    loyalty_tier VARCHAR(50),
    total_lifetime_value NUMERIC(12,2),
    total_orders_placed INTEGER,
    is_active BOOLEAN
);

select *from customers;

--Delivery Partners--

CREATE TABLE delivery_partners (
    partner_id VARCHAR(50) PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone_number VARCHAR(30),
    city VARCHAR(100),
    assigned_store_id VARCHAR(50),
    vehicle_type VARCHAR(50),
    driving_license_no VARCHAR(100),
    joining_date DATE,
    total_deliveries INTEGER,
    partner_rating NUMERIC(3,2),
    avg_delivery_time_min NUMERIC(8,2),
    status VARCHAR(50)
);

select * from delivery_partners;


CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    store_id VARCHAR(50),
    partner_id VARCHAR(50),
    order_datetime TIMESTAMP,
    delivery_datetime TIMESTAMP,
    delivery_time_min NUMERIC(8,2),
    order_status VARCHAR(50),
    total_amount NUMERIC(12,2),
    distance_km NUMERIC(8,2),
    payment_method VARCHAR(50),
    coupon_applied VARCHAR(100),
    discount_amount NUMERIC(12,2),
    final_amount NUMERIC(12,2)
);

select * from orders;

CREATE TABLE order_items (
    order_item_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    product_name VARCHAR(255),
    category VARCHAR(100),
    quantity INTEGER,
    price_per_unit NUMERIC(10,2),
    item_total NUMERIC(12,2)
);

select * from order_items;


CREATE TABLE payments (
    payment_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    transaction_id VARCHAR(100),
    payment_method VARCHAR(50),
    payment_gateway VARCHAR(100),
    transaction_amount NUMERIC(12,2),
    payment_status VARCHAR(50),
    payment_datetime TIMESTAMP,
    refund_amount NUMERIC(12,2),
    refund_datetime TIMESTAMP
);

select * from payments;

CREATE TABLE inventory (
    inventory_id VARCHAR(50) PRIMARY KEY,
    store_id VARCHAR(50),
    product_id VARCHAR(50),
    stock_level INTEGER,
    reorder_level INTEGER,
    stock_status VARCHAR(50),
    last_restocked_date DATE,
    capacity_percent NUMERIC(6,2),
    last_updated TIMESTAMP
);

select * from inventory;

CREATE TABLE offers (
    offer_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    offer_name VARCHAR(255),
    offer_type VARCHAR(100),
    discount_amount NUMERIC(12,2),
    sales_generated NUMERIC(12,2),
    redemption_rate NUMERIC(6,2),
    roi NUMERIC(10,2),
    offer_date DATE,
    status VARCHAR(50)
);

select * from offers;

-- How has revenue changed over time, and which cities and product categories are contributing the most to overall revenue?

SELECT
    DATE_TRUNC('month', order_datetime)::DATE AS month,
    SUM(final_amount) AS total_revenue
FROM orders
WHERE order_status = 'Delivered'
  AND order_datetime IS NOT NULL
GROUP BY 1
ORDER BY 1;

SELECT
    s.city,
    SUM(o.final_amount) AS total_revenue
FROM orders o
JOIN stores s
    ON o.store_id = s.store_id
WHERE o.order_status = 'Delivered'
GROUP BY s.city
ORDER BY total_revenue DESC;

SELECT
    oi.category,
    SUM(oi.item_total) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY oi.category
ORDER BY total_revenue DESC;

--What percentage of orders are delivered, cancelled, or returned, and which cities have the highest operational issues?

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage
FROM orders
GROUP BY order_status
ORDER BY order_percentage DESC;

SELECT
    s.city,
    COUNT(o.order_id) AS total_orders,
    COUNT(*) FILTER (
        WHERE o.order_status IN ('Cancelled', 'Returned')
    ) AS issue_orders,
    ROUND(
        COUNT(*) FILTER (
            WHERE o.order_status IN ('Cancelled', 'Returned')
        ) * 100.0 / COUNT(*),
        2
    ) AS issue_rate
FROM orders o
JOIN stores s
    ON o.store_id = s.store_id
GROUP BY s.city
ORDER BY issue_rate DESC;

---Who are our highest-value customers based on total spending and order frequency, and how does customer value vary across loyalty tiers?

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.loyalty_tier,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(SUM(o.final_amount), 2) AS total_spending,
    ROUND(AVG(o.final_amount), 2) AS average_order_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.loyalty_tier
ORDER BY total_spending DESC
LIMIT 20;

SELECT
    c.loyalty_tier,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(SUM(o.final_amount), 2) AS total_revenue,
    ROUND(AVG(o.final_amount), 2) AS average_order_value,
    ROUND(
        SUM(o.final_amount) /
        COUNT(DISTINCT c.customer_id),
        2
    ) AS revenue_per_customer
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status = 'Delivered'
GROUP BY c.loyalty_tier
ORDER BY revenue_per_customer DESC;

-- Which delivery partners and vehicle types are handling the highest workloads, and how does their delivery performance compare?

SELECT
    dp.partner_id,
    dp.first_name,
    dp.last_name,
    dp.vehicle_type,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(AVG(o.delivery_time_min), 2) AS avg_delivery_time_min,
    ROUND(AVG(dp.partner_rating), 2) AS partner_rating,
    ROUND(SUM(o.final_amount), 2) AS revenue_handled
FROM delivery_partners dp
JOIN orders o
    ON dp.partner_id = o.partner_id
WHERE o.order_status = 'Delivered'
GROUP BY
    dp.partner_id,
    dp.first_name,
    dp.last_name,
    dp.vehicle_type
ORDER BY delivered_orders DESC
LIMIT 20;

SELECT
    dp.vehicle_type,
    COUNT(DISTINCT dp.partner_id) AS delivery_partners,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(
        COUNT(o.order_id) * 1.0 /
        COUNT(DISTINCT dp.partner_id),
        2
    ) AS orders_per_partner,
    ROUND(AVG(o.delivery_time_min), 2) AS avg_delivery_time_min,
    ROUND(AVG(dp.partner_rating), 2) AS avg_partner_rating,
    ROUND(SUM(o.final_amount), 2) AS revenue_handled
FROM delivery_partners dp
JOIN orders o
    ON dp.partner_id = o.partner_id
WHERE o.order_status = 'Delivered'
GROUP BY dp.vehicle_type
ORDER BY orders_per_partner DESC;

-- Which cities have the highest delivery workload per active delivery partner, and where might additional fleet capacity be required?

SELECT
    dp.city,
    COUNT(DISTINCT dp.partner_id) FILTER (
        WHERE dp.status = 'Active'
    ) AS active_partners,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(
        COUNT(o.order_id) * 1.0 /
        NULLIF(
            COUNT(DISTINCT dp.partner_id) FILTER (
                WHERE dp.status = 'Active'
            ), 0
        ),
        2
    ) AS orders_per_active_partner
FROM delivery_partners dp
LEFT JOIN orders o
    ON dp.partner_id = o.partner_id
    AND o.order_status = 'Delivered'
GROUP BY dp.city
ORDER BY orders_per_active_partner DESC;

---Which products and stores have the highest stock-out rates, and what categories are most affected?


SELECT
    i.product_id,
    p.product_name,
    p.category,
    COUNT(*) AS inventory_records,
    COUNT(*) FILTER (
        WHERE i.stock_status = 'Out of Stock'
    ) AS stockout_records,
    ROUND(
        COUNT(*) FILTER (
            WHERE i.stock_status = 'Out of Stock'
        ) * 100.0 / COUNT(*),
        2
    ) AS stockout_rate
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
GROUP BY
    i.product_id,
    p.product_name,
    p.category
HAVING COUNT(*) >= 5
ORDER BY stockout_rate DESC
LIMIT 20;

SELECT
    i.store_id,
    s.store_name,
    s.city,
    COUNT(*) AS inventory_records,
    COUNT(*) FILTER (
        WHERE i.stock_status = 'Out of Stock'
    ) AS stockout_records,
    ROUND(
        COUNT(*) FILTER (
            WHERE i.stock_status = 'Out of Stock'
        ) * 100.0 / COUNT(*),
        2
    ) AS stockout_rate
FROM inventory i
JOIN stores s
    ON i.store_id = s.store_id
GROUP BY
    i.store_id,
    s.store_name,
    s.city
ORDER BY stockout_rate DESC;

SELECT
    p.category,
    COUNT(*) AS inventory_records,
    COUNT(*) FILTER (
        WHERE i.stock_status = 'Out of Stock'
    ) AS stockout_records,
    ROUND(
        COUNT(*) FILTER (
            WHERE i.stock_status = 'Out of Stock'
        ) * 100.0 / COUNT(*),
        2
    ) AS stockout_rate
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
GROUP BY p.category
ORDER BY stockout_rate DESC;

--- What days and periods experience the highest order demand, and how does demand vary across cities?

SELECT
    EXTRACT(DOW FROM order_datetime) AS day_number,
    TO_CHAR(order_datetime, 'Day') AS day_of_week,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'Delivered'
  AND order_datetime IS NOT NULL
GROUP BY
    EXTRACT(DOW FROM order_datetime),
    TO_CHAR(order_datetime, 'Day')
ORDER BY total_orders DESC;

SELECT
    DATE_TRUNC('month', order_datetime)::DATE AS month,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'Delivered'
  AND order_datetime IS NOT NULL
GROUP BY 1
ORDER BY total_orders DESC;

SELECT
    s.city,
    COUNT(o.order_id) AS total_orders,
    ROUND(
        COUNT(o.order_id) * 100.0 /
        SUM(COUNT(o.order_id)) OVER (),
        2
    ) AS demand_share_percent
FROM orders o
JOIN stores s
    ON o.store_id = s.store_id
WHERE o.order_status = 'Delivered'
GROUP BY s.city
ORDER BY total_orders DESC;

--Which offers generate the highest sales and ROI, and are higher discounts actually associated with higher sales?

SELECT
    offer_id,
    offer_name,
    offer_type,
    ROUND(discount_amount, 2) AS discount_amount,
    ROUND(sales_generated, 2) AS sales_generated,
    ROUND(roi, 2) AS roi
FROM offers
ORDER BY sales_generated DESC
LIMIT 20;

SELECT
    offer_id,
    offer_name,
    offer_type,
    ROUND(discount_amount, 2) AS discount_amount,
    ROUND(sales_generated, 2) AS sales_generated,
    ROUND(roi, 2) AS roi
FROM offers
WHERE roi IS NOT NULL
ORDER BY roi DESC
LIMIT 20;

SELECT
    CASE
        WHEN discount_amount < 50 THEN 'Low Discount'
        WHEN discount_amount < 100 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS discount_band,
    COUNT(*) AS offer_count,
    ROUND(AVG(discount_amount), 2) AS avg_discount,
    ROUND(AVG(sales_generated), 2) AS avg_sales_generated,
    ROUND(AVG(roi), 2) AS avg_roi
FROM offers
GROUP BY 1
ORDER BY avg_discount;

--Which dark stores generate the highest revenue and order volume, and how does their performance compare with their daily capacity?


SELECT
    s.store_id,
    s.store_name,
    s.city,
    s.daily_order_capacity,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(
        SUM(o.final_amount),
        2
    ) AS total_revenue,
    ROUND(
        COUNT(o.order_id) * 1.0 /
        NULLIF(s.daily_order_capacity, 0),
        2
    ) AS capacity_utilization_ratio
FROM stores s
LEFT JOIN orders o
    ON s.store_id = o.store_id
    AND o.order_status = 'Delivered'
GROUP BY
    s.store_id,
    s.store_name,
    s.city,
    s.daily_order_capacity
ORDER BY total_revenue DESC;

SELECT
    s.store_id,
    s.store_name,
    s.city,
    s.daily_order_capacity,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(SUM(o.final_amount), 2) AS total_revenue
FROM stores s
JOIN orders o
    ON s.store_id = o.store_id
WHERE o.order_status = 'Delivered'
GROUP BY
    s.store_id,
    s.store_name,
    s.city,
    s.daily_order_capacity
ORDER BY delivered_orders DESC
LIMIT 10;


WITH daily_store_orders AS (
    SELECT
        store_id,
        DATE(order_datetime) AS order_date,
        COUNT(order_id) AS daily_orders
    FROM orders
    WHERE order_status = 'Delivered'
      AND order_datetime IS NOT NULL
    GROUP BY store_id, DATE(order_datetime)
)
SELECT
    s.store_id,
    s.store_name,
    s.city,
    s.daily_order_capacity,
    ROUND(AVG(d.daily_orders), 2) AS avg_daily_orders,
    ROUND(
        AVG(d.daily_orders) * 100.0 /
        NULLIF(s.daily_order_capacity, 0),
        2
    ) AS avg_capacity_utilization_percent,
    ROUND(SUM(o.final_amount), 2) AS total_revenue
FROM stores s
JOIN daily_store_orders d
    ON s.store_id = d.store_id
JOIN orders o
    ON s.store_id = o.store_id
    AND o.order_status = 'Delivered'
GROUP BY
    s.store_id,
    s.store_name,
    s.city,
    s.daily_order_capacity
ORDER BY avg_capacity_utilization_percent DESC;

-- Which cities, stores, products, customers, and operational areas are driving the biggest opportunities or risks for the business?

WITH city_performance AS (
    SELECT
        s.city,
        COUNT(o.order_id) AS delivered_orders,
        ROUND(SUM(o.final_amount), 2) AS revenue,
        ROUND(
            COUNT(*) FILTER (
                WHERE o.order_status IN ('Cancelled', 'Returned')
            ) * 100.0 / COUNT(*),
            2
        ) AS issue_rate
    FROM orders o
    JOIN stores s
        ON o.store_id = s.store_id
    GROUP BY s.city
),
store_performance AS (
    SELECT
        s.store_id,
        s.store_name,
        s.city,
        COUNT(o.order_id) AS delivered_orders,
        ROUND(SUM(o.final_amount), 2) AS revenue
    FROM stores s
    JOIN orders o
        ON s.store_id = o.store_id
    WHERE o.order_status = 'Delivered'
    GROUP BY s.store_id, s.store_name, s.city
),
product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS units_sold,
        ROUND(SUM(oi.item_total), 2) AS revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.product_id, p.product_name, p.category
),
customer_performance AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.loyalty_tier,
        COUNT(o.order_id) AS delivered_orders,
        ROUND(SUM(o.final_amount), 2) AS spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.loyalty_tier
),
stockout_performance AS (
    SELECT
        p.category,
        COUNT(*) FILTER (
            WHERE i.stock_status = 'Out of Stock'
        ) AS stockout_records,
        COUNT(*) AS inventory_records,
        ROUND(
            COUNT(*) FILTER (
                WHERE i.stock_status = 'Out of Stock'
            ) * 100.0 / COUNT(*),
            2
        ) AS stockout_rate
    FROM inventory i
    JOIN products p
        ON i.product_id = p.product_id
    GROUP BY p.category
)
SELECT
    'City' AS area_type,
    city AS entity,
    revenue,
    delivered_orders,
    issue_rate AS risk_metric
FROM city_performance
UNION ALL
SELECT
    'Store',
    store_name,
    revenue,
    delivered_orders,
    NULL
FROM store_performance
UNION ALL
SELECT
    'Product',
    product_name,
    revenue,
    units_sold,
    NULL
FROM product_performance
UNION ALL
SELECT
    'Customer',
    CONCAT(first_name, ' ', last_name),
    spending,
    delivered_orders,
    NULL
FROM customer_performance
UNION ALL
SELECT
    'Category',
    category,
    NULL,
    inventory_records,
    stockout_rate
FROM stockout_performance
ORDER BY revenue DESC NULLS LAST;