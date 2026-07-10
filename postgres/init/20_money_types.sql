\connect analytics

DROP VIEW IF EXISTS vw_sales_daily;
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

DROP VIEW IF EXISTS vw_customer_summary;
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
