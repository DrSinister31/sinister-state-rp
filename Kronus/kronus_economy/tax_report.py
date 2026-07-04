from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled
from budget import get_treasury_summary, get_tax_summary_since

config = Config.from_env()
supabase = get_supabase(config)


async def generate_weekly_tax_report() -> dict:
    week_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()

    tax = await get_tax_summary_since(week_ago)
    treasury = await get_treasury_summary()

    allocations = supabase.table("city_budget_allocations").select("fund_name, kronus_default_percentage").execute()

    report = {
        "title": "Weekly Tax Report — Sinister State Treasury",
        "tax_summary": tax,
        "treasury": treasury,
        "allocations": allocations.data or [],
        "week_start": week_ago,
        "generated_at": datetime.utcnow().isoformat(),
    }

    supabase.table("kronus_metrics").insert({
        "metric_name": "weekly_tax_report",
        "value": float(tax.get("total", 0)),
        "metadata_json": report,
        "recorded_at": datetime.utcnow().isoformat()
    }).execute()

    return report


def format_tax_report_embed(report: dict) -> dict:
    tax = report["tax_summary"]
    treasury = report["treasury"]

    fields = []
    fields.append({"name": "Income Tax", "value": f"${tax.get('income', 0):,}", "inline": True})
    fields.append({"name": "Business Tax", "value": f"${tax.get('business', 0):,}", "inline": True})
    fields.append({"name": "Sales Tax", "value": f"${tax.get('sales', 0):,}", "inline": True})
    fields.append({"name": "\u200b", "value": "\u200b", "inline": False})

    fund_lines = []
    for fund_name, balance in sorted(treasury.items()):
        label = fund_name.replace("_", " ").title()
        fund_lines.append(f"**{label}**: ${balance:,}")
    fields.append({"name": "Treasury Balances", "value": "\n".join(fund_lines), "inline": False})

    total = tax.get("total", 0)
    color = 0xBF5700
    if total > 1000000:
        color = 0x4CAF50
    elif total < 100000:
        color = 0xe53935

    return {
        "title": report["title"],
        "description": f"Tax collected this week: **${total:,}** from {tax.get('transaction_count', 0)} transactions.\nWeek of {(report['week_start'])[:10]}",
        "color": color,
        "fields": fields,
        "footer": "Sinister State TX — Kronus Federal Reserve",
    }
