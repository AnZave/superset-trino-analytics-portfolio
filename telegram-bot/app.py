import argparse
import os
import time
from datetime import datetime, timezone

import requests
import trino


TRINO_HOST = os.getenv("TRINO_HOST", "trino")
TRINO_PORT = int(os.getenv("TRINO_PORT", "8080"))
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
ALLOWED_CHAT_ID = os.getenv("TELEGRAM_ALLOWED_CHAT_ID", "")
DAILY_REPORT_HOUR = int(os.getenv("TELEGRAM_DAILY_REPORT_HOUR", "9"))
SUPERSET_PUBLIC_URL = os.getenv("SUPERSET_PUBLIC_URL", "http://127.0.0.1:8088").rstrip("/")


def query(sql: str):
    connection = trino.dbapi.connect(
        host=TRINO_HOST,
        port=TRINO_PORT,
        user="telegram_kpi_bot",
        catalog="postgresql",
        schema="public",
    )
    cursor = connection.cursor()
    cursor.execute(sql)
    return cursor.fetchall()


def latest_date():
    return query("SELECT max(order_date) FROM vw_sales_daily")[0][0]


def latest_report() -> str:
    report_date, orders, revenue, profit = query(
        """
        SELECT
            max(order_date),
            sum(orders),
            sum(revenue),
            sum(gross_profit)
        FROM vw_sales_daily
        WHERE order_date = (SELECT max(order_date) FROM vw_sales_daily)
        """
    )[0]
    margin = profit / revenue if revenue else 0
    return (
        "📊 Latest daily KPI report\n"
        f"Date: {report_date}\n\n"
        f"Orders: {orders:,.0f}\n"
        f"Revenue: ${revenue:,.2f}\n"
        f"Gross profit: ${profit:,.2f}\n"
        f"Gross margin: {margin:.1%}"
    )


def week_report() -> str:
    start_date, end_date, orders, revenue, profit = query(
        """
        SELECT
            min(order_date),
            max(order_date),
            sum(orders),
            sum(revenue),
            sum(gross_profit)
        FROM vw_sales_daily
        WHERE order_date BETWEEN
            date_add('day', -6, (SELECT max(order_date) FROM vw_sales_daily))
            AND (SELECT max(order_date) FROM vw_sales_daily)
        """
    )[0]
    margin = profit / revenue if revenue else 0
    return (
        "📈 Latest 7-day KPI report\n"
        f"Period: {start_date} — {end_date}\n\n"
        f"Orders: {orders:,.0f}\n"
        f"Revenue: ${revenue:,.2f}\n"
        f"Gross profit: ${profit:,.2f}\n"
        f"Gross margin: {margin:.1%}"
    )


def change(current, previous):
    if not previous:
        return "n/a"
    value = (current - previous) / previous
    arrow = "▲" if value >= 0 else "▼"
    return f"{arrow} {abs(value):.1%}"


def compare_report() -> str:
    rows = query(
        """
        WITH bounds AS (
            SELECT max(order_date) AS max_date FROM vw_sales_daily
        ), periods AS (
            SELECT
                CASE
                    WHEN order_date > date_add('day', -7, max_date) THEN 'current'
                    ELSE 'previous'
                END AS period,
                sum(orders) AS orders,
                sum(revenue) AS revenue,
                sum(gross_profit) AS profit
            FROM vw_sales_daily CROSS JOIN bounds
            WHERE order_date BETWEEN date_add('day', -13, max_date) AND max_date
            GROUP BY 1
        )
        SELECT period, orders, revenue, profit FROM periods
        """
    )
    values = {period: (orders, revenue, profit) for period, orders, revenue, profit in rows}
    current = values.get("current", (0, 0, 0))
    previous = values.get("previous", (0, 0, 0))
    current_margin = current[2] / current[1] if current[1] else 0
    previous_margin = previous[2] / previous[1] if previous[1] else 0
    margin_change = (current_margin - previous_margin) * 100
    margin_arrow = "▲" if margin_change >= 0 else "▼"
    return (
        "🔄 Last 7 days vs previous 7 days\n\n"
        f"Revenue: ${current[1]:,.2f}  {change(current[1], previous[1])}\n"
        f"Orders: {current[0]:,.0f}  {change(current[0], previous[0])}\n"
        f"Gross profit: ${current[2]:,.2f}  {change(current[2], previous[2])}\n"
        f"Gross margin: {current_margin:.1%}  {margin_arrow} {abs(margin_change):.1f} pp"
    )


def countries_report() -> str:
    rows = query(
        """
        SELECT country, sum(revenue) AS revenue, sum(orders) AS orders
        FROM vw_sales_daily
        GROUP BY 1
        ORDER BY revenue DESC
        """
    )
    lines = ["🌍 Revenue by country"]
    for index, (country, revenue, orders) in enumerate(rows, 1):
        lines.append(f"{index}. {country}: ${revenue:,.0f} · {orders:,.0f} orders")
    return "\n".join(lines)


def segments_report() -> str:
    rows = query(
        """
        SELECT customer_segment, count(*) AS customers, sum(lifetime_revenue) AS revenue
        FROM vw_customer_summary
        GROUP BY 1
        ORDER BY revenue DESC
        """
    )
    lines = ["👥 Customer value segments"]
    for segment, customers, revenue in rows:
        lines.append(f"• {segment}: {customers:,.0f} customers · ${revenue:,.0f}")
    return "\n".join(lines)


def status_report() -> str:
    latest, row_count = query(
        "SELECT max(order_date), sum(orders) FROM vw_sales_daily"
    )[0]
    return (
        "✅ Analytics platform status\n\n"
        "Trino: OK\n"
        "PostgreSQL connector: OK\n"
        f"Latest business date: {latest}\n"
        f"Completed orders available: {row_count:,.0f}"
    )


def dashboards_report() -> str:
    return (
        "🔗 Superset dashboards\n\n"
        f"Executive Overview:\n{SUPERSET_PUBLIC_URL}/superset/dashboard/ecommerce-executive-overview/\n\n"
        f"Customer Analytics:\n{SUPERSET_PUBLIC_URL}/superset/dashboard/customer-analytics/\n\n"
        "Local URLs open on the computer running Docker."
    )


def telegram(method: str, payload: dict):
    if not BOT_TOKEN:
        raise RuntimeError("TELEGRAM_BOT_TOKEN is not configured")
    response = requests.post(
        f"https://api.telegram.org/bot{BOT_TOKEN}/{method}",
        json=payload,
        timeout=40,
    )
    response.raise_for_status()
    result = response.json()
    if not result.get("ok"):
        raise RuntimeError(result.get("description", "Telegram API error"))
    return result["result"]


def command_keyboard():
    return {
        "keyboard": [
            ["/latest", "/week"],
            ["/compare", "/countries"],
            ["/segments", "/status"],
            ["/dashboard", "/help"],
        ],
        "resize_keyboard": True,
        "is_persistent": True,
        "input_field_placeholder": "Choose a KPI report",
    }


def send_message(chat_id, text: str, show_keyboard: bool = False):
    payload = {"chat_id": chat_id, "text": text}
    if show_keyboard:
        payload["reply_markup"] = command_keyboard()
    telegram("sendMessage", payload)


def authorized(chat_id) -> bool:
    return not ALLOWED_CHAT_ID or str(chat_id) == str(ALLOWED_CHAT_ID)


def handle_message(message: dict):
    chat_id = message.get("chat", {}).get("id")
    text = message.get("text", "").split()[0].lower()
    if not chat_id or not authorized(chat_id):
        return
    if text in {"/start", "/help"}:
        send_message(
            chat_id,
            "Choose a report using the buttons below:\n"
            "/latest — latest daily KPI\n"
            "/week — latest 7 days\n"
            "/compare — period comparison\n"
            "/countries — country performance\n"
            "/segments — customer value segments\n"
            "/status — platform and data freshness\n"
            "/dashboard — Superset links",
            show_keyboard=True,
        )
    elif text == "/latest":
        send_message(chat_id, latest_report())
    elif text == "/week":
        send_message(chat_id, week_report())
    elif text == "/compare":
        send_message(chat_id, compare_report())
    elif text == "/countries":
        send_message(chat_id, countries_report())
    elif text == "/segments":
        send_message(chat_id, segments_report())
    elif text == "/status":
        send_message(chat_id, status_report())
    elif text == "/dashboard":
        send_message(chat_id, dashboards_report())


def run_bot():
    offset = None
    last_daily_date = None
    while True:
        payload = {"timeout": 25, "allowed_updates": ["message"]}
        if offset is not None:
            payload["offset"] = offset
        for update in telegram("getUpdates", payload):
            offset = update["update_id"] + 1
            if "message" in update:
                handle_message(update["message"])

        now = datetime.now(timezone.utc)
        if (
            ALLOWED_CHAT_ID
            and now.hour == DAILY_REPORT_HOUR
            and last_daily_date != now.date()
        ):
            send_message(ALLOWED_CHAT_ID, latest_report())
            last_daily_date = now.date()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dry-run",
        choices=["latest", "week", "compare", "countries", "segments", "status", "all"],
    )
    args = parser.parse_args()
    if args.dry_run:
        if args.dry_run in {"latest", "all"}:
            print(latest_report())
        if args.dry_run in {"week", "all"}:
            print("\n" + week_report())
        if args.dry_run in {"compare", "all"}:
            print("\n" + compare_report())
        if args.dry_run in {"countries", "all"}:
            print("\n" + countries_report())
        if args.dry_run in {"segments", "all"}:
            print("\n" + segments_report())
        if args.dry_run in {"status", "all"}:
            print("\n" + status_report())
        return
    run_bot()


if __name__ == "__main__":
    main()
