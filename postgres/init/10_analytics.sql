\connect analytics

CREATE TABLE customers (
    customer_id bigint PRIMARY KEY,
    registered_at date NOT NULL,
    country text NOT NULL,
    acquisition_channel text NOT NULL
);

CREATE TABLE products (
    product_id bigint PRIMARY KEY,
    product_name text NOT NULL,
    category text NOT NULL,
    unit_cost numeric(12, 2) NOT NULL
);

CREATE TABLE orders (
    order_id bigint PRIMARY KEY,
    ordered_at timestamp NOT NULL,
    customer_id bigint NOT NULL REFERENCES customers(customer_id),
    product_id bigint NOT NULL REFERENCES products(product_id),
    quantity integer NOT NULL,
    unit_price numeric(12, 2) NOT NULL,
    status text NOT NULL
);

INSERT INTO customers
SELECT
    customer_id,
    date '2024-01-01' + ((customer_id * 17) % 700)::integer,
    CASE
        WHEN get_byte(decode(md5('country-' || customer_id::text), 'hex'), 0) < 90 THEN 'United States'
        WHEN get_byte(decode(md5('country-' || customer_id::text), 'hex'), 0) < 149 THEN 'Germany'
        WHEN get_byte(decode(md5('country-' || customer_id::text), 'hex'), 0) < 195 THEN 'United Kingdom'
        WHEN get_byte(decode(md5('country-' || customer_id::text), 'hex'), 0) < 231 THEN 'Poland'
        ELSE 'Ukraine'
    END,
    CASE
        WHEN get_byte(decode(md5('channel-' || customer_id::text), 'hex'), 0) < 77 THEN 'Organic'
        WHEN get_byte(decode(md5('channel-' || customer_id::text), 'hex'), 0) < 141 THEN 'Google Ads'
        WHEN get_byte(decode(md5('channel-' || customer_id::text), 'hex'), 0) < 192 THEN 'Meta Ads'
        WHEN get_byte(decode(md5('channel-' || customer_id::text), 'hex'), 0) < 230 THEN 'Referral'
        ELSE 'Email'
    END
FROM generate_series(1, 2500) AS g(customer_id);

INSERT INTO products VALUES
    (1, 'Wireless Headphones', 'Electronics', 38.00),
    (2, 'Mechanical Keyboard', 'Electronics', 52.00),
    (3, 'Desk Lamp', 'Home', 18.00),
    (4, 'Coffee Grinder', 'Home', 31.00),
    (5, 'Running Shoes', 'Sports', 44.00),
    (6, 'Yoga Mat', 'Sports', 15.00),
    (7, 'City Backpack', 'Accessories', 27.00),
    (8, 'Travel Bottle', 'Accessories', 8.00);

INSERT INTO orders
SELECT
    order_id,
    timestamp '2025-01-01 00:00:00'
        + ((order_id * 37) % 545) * interval '1 day'
        + ((order_id * 13) % 24) * interval '1 hour',
    ((order_id * 19) % 2500) + 1,
    ((order_id * 7) % 8) + 1,
    ((order_id % 4) + 1)::integer,
    round((25 + ((order_id * 23) % 130) + ((order_id % 99)::numeric / 100)), 2),
    (ARRAY['completed','completed','completed','refunded','cancelled'])[((order_id - 1) % 5) + 1]
FROM generate_series(1, 30000) AS g(order_id);

CREATE INDEX orders_ordered_at_idx ON orders (ordered_at);
CREATE INDEX orders_customer_id_idx ON orders (customer_id);

CREATE VIEW vw_sales_daily AS
SELECT
    o.ordered_at::date AS order_date,
    c.country,
    c.acquisition_channel,
    p.category,
    count(DISTINCT o.order_id) AS orders,
    count(DISTINCT o.customer_id) AS customers,
    sum(o.quantity) AS units,
    round(sum(o.quantity * o.unit_price), 2)::double precision AS revenue,
    round(sum(o.quantity * (o.unit_price - p.unit_cost)), 2)::double precision AS gross_profit
FROM orders o
JOIN customers c USING (customer_id)
JOIN products p USING (product_id)
WHERE o.status = 'completed'
GROUP BY 1, 2, 3, 4;

CREATE VIEW vw_customer_summary AS
SELECT
    c.customer_id,
    c.registered_at,
    c.country,
    c.acquisition_channel,
    min(o.ordered_at)::date AS first_order_date,
    max(o.ordered_at)::date AS last_order_date,
    count(DISTINCT o.order_id) AS completed_orders,
    round(coalesce(sum(o.quantity * o.unit_price), 0), 2)::double precision AS lifetime_revenue
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.customer_id
   AND o.status = 'completed'
GROUP BY 1, 2, 3, 4;
