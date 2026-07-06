import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import json
from ftplib import FTP
from shared.supabase_client import get_supabase
from shared.config import Config

config = Config.from_env()
supabase = get_supabase(config)

FTP_HOST = "79.127.172.121"
FTP_USER = "FEN8gHlIbozd1X"
FTP_PASS = "'CPb4{ams3Lzv=t~UlViy8(PJ)pqnA"


def parse_jobs_lua(content: str) -> list[dict]:
    jobs = []
    current_job = None
    current_grade = None
    brace_depth = 0
    in_grades = False

    lines = content.split("\n")
    for line in lines:
        stripped = line.strip()

        if stripped.startswith("['") and stripped.endswith("{") and "=" in stripped:
            job_key = stripped.split("['")[1].split("']")[0]
            current_job = {"name": job_key, "label": "", "type": "none", "grades": []}
            in_grades = False
            continue

        if current_job:
            if "label =" in stripped:
                val = stripped.split("label = ")[1].strip().strip("'").strip('"').rstrip(",").rstrip("'").rstrip('"')
                current_job["label"] = val
            elif "type =" in stripped and "grade" not in stripped.lower():
                val = stripped.split("type = ")[1].strip().strip("'").strip('"').rstrip(",").rstrip("'").rstrip('"')
                current_job["type"] = val
            elif "grades = {" in stripped:
                in_grades = True
                continue
            elif in_grades and "[" in stripped and "] =" in stripped:
                grade_key = stripped.split("[")[1].split("]")[0]
                try:
                    grade_num = int(grade_key)
                except:
                    continue
                current_grade = {"level": grade_num, "name": "", "payment": 0, "isboss": False}
                # Inline grade format: [0] = { name = '...', payment = 150 },
                if "name =" in stripped:
                    name_part = stripped.split("name = ")[1].split(",")[0].strip().strip("'").strip('"')
                    current_grade["name"] = name_part
                if "payment =" in stripped:
                    pay_part = stripped.split("payment = ")[1].split(",")[0].split("}")[0].strip().rstrip(",").strip()
                    try:
                        current_grade["payment"] = int(pay_part)
                    except:
                        current_grade["payment"] = 0
                if "isboss =" in stripped:
                    current_grade["isboss"] = "true" in stripped.lower()
                # If single-line grade definition
                if "}," in stripped and current_grade:
                    current_job["grades"].append(current_grade)
                    current_grade = None
            elif current_grade and not stripped.startswith("[") and "name =" in stripped:
                val = stripped.split("name = ")[1].strip().strip("'").strip('"').rstrip(",")
                current_grade["name"] = val
            elif current_grade and "payment =" in stripped:
                val = stripped.split("payment = ")[1].strip().rstrip(",").strip()
                try:
                    current_grade["payment"] = int(val)
                except:
                    current_grade["payment"] = 0
            elif current_grade and "isboss =" in stripped:
                current_grade["isboss"] = "true" in stripped.lower()
            elif current_grade and "}," in stripped:
                current_job["grades"].append(current_grade)
                current_grade = None
            elif "}," in stripped and in_grades and not current_grade:
                in_grades = False
                jobs.append(current_job)
                current_job = None

    if current_job:
        jobs.append(current_job)
    return jobs


async def sync_jobs_to_supabase():
    ftp = FTP()
    ftp.connect(FTP_HOST, 21, timeout=15)
    try: ftp.login(FTP_USER, "warmup")
    except: pass
    try: ftp.quit()
    except: pass

    ftp = FTP()
    ftp.connect(FTP_HOST, 21, timeout=15)
    ftp.login(FTP_USER, FTP_PASS)

    lines = []
    ftp.retrlines("RETR /servers/QboxProject_4826CC.base/resources/[qbx]/qbx_core/shared/jobs.lua", lines.append)
    ftp.quit()

    content = "\n".join(lines)
    jobs = parse_jobs_lua(content)

    summary = []
    for job in jobs:
        grades_text = []
        for g in sorted(job["grades"], key=lambda x: x["level"]):
            grades_text.append(f"  Grade {g['level']}: {g['name']} (${g['payment']})")

        job_info = {
            "name": job["name"],
            "label": job["label"],
            "type": job["type"],
            "grade_count": len(job["grades"]),
            "grade_scale": f"0-{max((g['level'] for g in job['grades']), default=0)}",
            "grades": job["grades"],
            "pay_range": f"${min((g['payment'] for g in job['grades']), default=0)}-${max((g['payment'] for g in job['grades']), default=0)}",
        }

        summary.append(job_info)

        supabase.table("bot_config").upsert({
            "key": f"job_info_{job['name']}",
            "value": json.dumps(job_info),
            "updated_at": "now()"
        }).execute()

    all_jobs = json.dumps(summary, indent=2)
    supabase.table("bot_config").upsert({
        "key": "kronus_job_knowledge",
        "value": all_jobs[:4000],
        "updated_at": "now()"
    }).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "job_sync",
        "context_json": {"jobs_synced": len(jobs)},
        "result": "completed"
    }).execute()

    return summary
