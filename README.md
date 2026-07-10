# E-commerce Analytics with Apache Superset and Trino

Portfolio project demonstrating a reproducible BI environment built with Apache Superset, Trino, PostgreSQL, and SQL.

## Business scenario

An e-commerce company needs a single view of revenue, gross profit, orders, customer acquisition, and retention. The solution exposes curated PostgreSQL datasets through Trino and visualizes them in Superset.

## Architecture

```text
Synthetic e-commerce data -> PostgreSQL -> Trino -> Apache Superset
```

## What this project demonstrates

- Reproducible local BI infrastructure with Docker Compose
- SQL data modeling for reusable business metrics
- Trino catalog configuration
- Superset connection and dashboard design
- Separation of raw transactional tables from reporting views

## Quick start

Requirements: Docker Desktop with Docker Compose and at least 6 GB of memory available to Docker.

1. Copy `.env.example` to `.env`.
2. Replace `SUPERSET_SECRET_KEY` with a long random string.
3. Keep the PostgreSQL credentials aligned with `trino/catalog/postgresql.properties` if you change them.
4. Start the stack:

   ```bash
   docker compose up --build -d
   ```

5. Open Superset at `http://localhost:8088` and sign in with the admin credentials from `.env`.
6. Add a database connection in **Settings -> Database Connections**:

   ```text
   trino://trino@trino:8080/postgresql/public
   ```

7. Test the connection, then add `vw_sales_daily` and `vw_customer_summary` as datasets.
8. Use the examples in `sql/dashboard_queries.sql` to create virtual datasets and charts.

Trino UI is available at `http://localhost:8080`.

## Suggested dashboard pages

### Executive overview

- Revenue
- Gross profit
- Order count
- Average order value
- Revenue and profit trend
- Revenue by country

Implemented native filters:

- Date range
- Country
- Acquisition channel
- Product category

The dashboard uses the reusable Modern Analytics SaaS CSS theme from
`assets/dashboard_theme.css`.

The version-controlled Superset export is stored in
`exports/ecommerce-executive-overview.zip`.

The Customer Analytics dashboard export is stored in
`exports/customer-analytics.zip`.

## Telegram KPI bot

The optional bot in `telegram-bot/` queries the same Trino reporting layer and
supports `/latest`, `/week`, `/compare`, `/countries`, `/segments`, `/status`,
and `/dashboard`. Test it without Telegram credentials:

```bash
docker compose --profile telegram run --rm telegram-bot python app.py --dry-run all
```

To run the real bot, add `TELEGRAM_BOT_TOKEN` and `TELEGRAM_ALLOWED_CHAT_ID` to
`.env`, then start it with:

```bash
docker compose --profile telegram up -d telegram-bot
```

### Sales and acquisition

- Revenue by category
- Revenue by acquisition channel
- Country/channel matrix
- Daily order trend

### Customer analytics

- One-time, repeat, and loyal customers
- Lifetime revenue by segment
- Customers by market and acquisition channel

## Resetting the demo

The initialization SQL runs only when PostgreSQL creates a new data volume. To rebuild the demo data:

```bash
docker compose down -v
docker compose up --build -d
```

This deletes only the containers and local Docker volume belonging to this demo project.

## Portfolio summary

> Built a reproducible open-source BI environment using Apache Superset, Trino, PostgreSQL, and Docker Compose. Modeled 30,000 synthetic e-commerce orders into reusable reporting views covering revenue, gross profit, customer acquisition, and customer segments. Connected Superset through Trino to provide interactive executive and operational dashboards.

## Next milestones

- Export version-controlled Superset dashboard assets
- Add Telegram KPI alerts
- Add a query-optimization benchmark
- Replace PostgreSQL source data with partitioned Parquet/Iceberg data
