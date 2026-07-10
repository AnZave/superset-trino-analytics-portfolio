\connect analytics

DROP VIEW IF EXISTS vw_customer_summary;
CREATE VIEW vw_customer_summary AS
WITH customer_orders AS (
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
    GROUP BY 1, 2, 3, 4
)
SELECT
    customer_id,
    registered_at,
    date_trunc('month', registered_at)::date AS registration_month,
    country,
    acquisition_channel,
    first_order_date,
    date_trunc('month', first_order_date)::date AS first_order_month,
    last_order_date,
    completed_orders,
    lifetime_revenue,
    CASE
        WHEN completed_orders = 0 THEN 'No purchase'
        WHEN lifetime_revenue < 1600 THEN 'Standard'
        WHEN lifetime_revenue < 2675 THEN 'Growth'
        WHEN lifetime_revenue < 3750 THEN 'High-value'
        ELSE 'VIP'
    END AS customer_segment
FROM customer_orders;
