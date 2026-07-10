# Dashboard specification

## Page 1 — Executive overview

The page answers: **Is the business growing profitably?**

| Chart | Metric or dimension | Recommended visualization |
|---|---|---|
| Revenue | `SUM(revenue)` | Big number with time comparison |
| Gross profit | `SUM(gross_profit)` | Big number with time comparison |
| Orders | `SUM(orders)` | Big number |
| Average order value | `SUM(revenue) / SUM(orders)` | Big number |
| Revenue and profit trend | `order_date`, revenue, gross profit | Mixed time-series chart |
| Revenue by country | `country`, revenue | Bar chart |

Global filters: date range, country, acquisition channel, category.

## Page 2 — Sales and acquisition

The page answers: **Which markets, channels, and categories drive results?**

| Chart | Metric or dimension | Recommended visualization |
|---|---|---|
| Revenue by category | category, revenue | Horizontal bar chart |
| Channel performance | acquisition channel, revenue, gross profit | Grouped bar chart |
| Market/channel contribution | country, acquisition channel, revenue | Pivot table with heatmap |
| Daily orders | order date, orders | Time-series line chart |

## Page 3 — Customer analytics

The page answers: **Are customers returning and which segments are valuable?**

| Chart | Metric or dimension | Recommended visualization |
|---|---|---|
| Customers by segment | customer segment, customers | Donut chart |
| Lifetime revenue by segment | customer segment, lifetime revenue | Bar chart |
| Customer geography | country, customers | Bar chart or map |
| Acquisition quality | acquisition channel, customers, lifetime revenue | Pivot table |

## Presentation rules

- Put the business question in each chart title.
- Use one currency format consistently.
- Limit categorical charts to a useful top N.
- Keep technical field names out of labels shown to business users.
- Add a dashboard subtitle explaining the reporting period and refresh cadence.
