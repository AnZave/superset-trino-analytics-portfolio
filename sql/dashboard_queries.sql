-- Executive KPI trend. Use this as a virtual dataset in Superset.
SELECT
    order_date,
    sum(revenue) AS revenue,
    sum(gross_profit) AS gross_profit,
    sum(orders) AS orders,
    sum(customers) AS customers,
    sum(revenue) / NULLIF(sum(orders), 0) AS average_order_value
FROM postgresql.public.vw_sales_daily
GROUP BY order_date
ORDER BY order_date;

-- Sales by market and acquisition channel.
SELECT
    country,
    acquisition_channel,
    sum(revenue) AS revenue,
    sum(gross_profit) AS gross_profit,
    sum(orders) AS orders
FROM postgresql.public.vw_sales_daily
GROUP BY country, acquisition_channel
ORDER BY revenue DESC;

-- Customer segmentation for a second dashboard page.
SELECT
    country,
    acquisition_channel,
    CASE
        WHEN completed_orders = 0 THEN 'No purchase'
        WHEN completed_orders = 1 THEN 'One-time'
        WHEN completed_orders BETWEEN 2 AND 4 THEN 'Repeat'
        ELSE 'Loyal'
    END AS customer_segment,
    count(*) AS customers,
    sum(lifetime_revenue) AS lifetime_revenue
FROM postgresql.public.vw_customer_summary
GROUP BY 1, 2, 3
ORDER BY lifetime_revenue DESC;

