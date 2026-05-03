@echo off
setlocal EnableExtensions

title Auto Leads System Health Check

set "APP_DIR=C:\AutoLeads\auto-leads"
set "VENV=%APP_DIR%\.venv"
set "CHECK_PY=%APP_DIR%\system_health_check.py"

echo.
echo ============================================================
echo  AUTO LEADS - SYSTEM HEALTH CHECK
echo ============================================================
echo.

cd /d "%APP_DIR%"

if not exist "%VENV%\Scripts\activate.bat" (
    echo [FEHLER] Venv nicht gefunden.
    pause
    exit /b 1
)

call "%VENV%\Scripts\activate.bat"

copy /y NUL "%CHECK_PY%" >nul

>> "%CHECK_PY%" echo from pathlib import Path
>> "%CHECK_PY%" echo import os
>> "%CHECK_PY%" echo import re
>> "%CHECK_PY%" echo import requests
>> "%CHECK_PY%" echo from dotenv import load_dotenv
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo APP = Path(r"C:\AutoLeads\auto-leads")
>> "%CHECK_PY%" echo load_dotenv(APP / ".env")
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo def ok(msg): print("[OK]", msg)
>> "%CHECK_PY%" echo def warn(msg): print("[WARNUNG]", msg)
>> "%CHECK_PY%" echo def fail(msg): print("[FEHLER]", msg)
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo print("")
>> "%CHECK_PY%" echo print("=== CONFIG CHECK ===")
>> "%CHECK_PY%" echo for key in ["SECRET_KEY","DATABASE_URL","GOOGLE_MAPS_API_KEY","PAGESPEED_API_KEY","EMAIL_PROVIDER","EMAIL_FROM"]:
>> "%CHECK_PY%" echo     val = os.getenv(key, "")
>> "%CHECK_PY%" echo     if val:
>> "%CHECK_PY%" echo         ok(f"{key} gesetzt")
>> "%CHECK_PY%" echo     else:
>> "%CHECK_PY%" echo         warn(f"{key} fehlt oder leer")
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo print("")
>> "%CHECK_PY%" echo print("=== FILE CHECK ===")
>> "%CHECK_PY%" echo required = [
>> "%CHECK_PY%" echo     "app/routes/leads.py",
>> "%CHECK_PY%" echo     "app/routes/dashboard.py",
>> "%CHECK_PY%" echo     "app/routes/outreach.py",
>> "%CHECK_PY%" echo     "app/services/pagespeed_service.py",
>> "%CHECK_PY%" echo     "app/services/website_audit_service.py",
>> "%CHECK_PY%" echo     "app/services/lead_score_service.py",
>> "%CHECK_PY%" echo     "app/services/outreach_draft_service.py",
>> "%CHECK_PY%" echo     "app/models.py",
>> "%CHECK_PY%" echo ]
>> "%CHECK_PY%" echo for rel in required:
>> "%CHECK_PY%" echo     if (APP / rel).exists():
>> "%CHECK_PY%" echo         ok(rel)
>> "%CHECK_PY%" echo     else:
>> "%CHECK_PY%" echo         fail(f"{rel} fehlt")
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo email_service = APP / "app/services/email_service.py"
>> "%CHECK_PY%" echo if email_service.exists():
>> "%CHECK_PY%" echo     ok("email_service.py vorhanden")
>> "%CHECK_PY%" echo else:
>> "%CHECK_PY%" echo     warn("email_service.py fehlt - echter Dashboard-Mailversand ist wahrscheinlich noch nicht eingebaut")
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo print("")
>> "%CHECK_PY%" echo print("=== PATCH CHECK ===")
>> "%CHECK_PY%" echo lead_score = (APP / "app/services/lead_score_service.py").read_text(encoding="utf-8")
>> "%CHECK_PY%" echo if "_as_aware_utc" in lead_score:
>> "%CHECK_PY%" echo     ok("Datetime-Fix in lead_score_service.py gefunden")
>> "%CHECK_PY%" echo else:
>> "%CHECK_PY%" echo     fail("Datetime-Fix fehlt: _as_aware_utc nicht gefunden")
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo outreach = (APP / "app/services/outreach_draft_service.py").read_text(encoding="utf-8")
>> "%CHECK_PY%" echo if "6000/100" in outreach or "* 100" in outreach and "score_seo" in outreach:
>> "%CHECK_PY%" echo     warn("Outreach-Score-Normalisierung prüfen: mögliche *100-Probleme")
>> "%CHECK_PY%" echo else:
>> "%CHECK_PY%" echo     ok("Kein offensichtlicher 6000/100-Textfehler im Outreach-Service")
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo print("")
>> "%CHECK_PY%" echo print("=== APP / DB CHECK ===")
>> "%CHECK_PY%" echo try:
>> "%CHECK_PY%" echo     from app import create_app
>> "%CHECK_PY%" echo     from app.extensions import db
>> "%CHECK_PY%" echo     from app.models import Lead, AuditResult, OutreachDraft, ContactAttempt
>> "%CHECK_PY%" echo     app = create_app()
>> "%CHECK_PY%" echo     with app.app_context():
>> "%CHECK_PY%" echo         db.create_all()
>> "%CHECK_PY%" echo         ok("App importiert und DB initialisiert")
>> "%CHECK_PY%" echo         print("Leads:", Lead.query.count())
>> "%CHECK_PY%" echo         print("Audits:", AuditResult.query.count())
>> "%CHECK_PY%" echo         print("Drafts:", OutreachDraft.query.count())
>> "%CHECK_PY%" echo         print("ContactAttempts:", ContactAttempt.query.count())
>> "%CHECK_PY%" echo         bad_drafts = OutreachDraft.query.filter(OutreachDraft.body.like("%%/100%%")).all()
>> "%CHECK_PY%" echo         suspicious = []
>> "%CHECK_PY%" echo         for d in bad_drafts:
>> "%CHECK_PY%" echo             if re.search(r"[0-9]{3,}/100", d.body or ""):
>> "%CHECK_PY%" echo                 suspicious.append(d.id)
>> "%CHECK_PY%" echo         if suspicious:
>> "%CHECK_PY%" echo             warn(f"Verdächtige Drafts mit Score >100 gefunden: {suspicious[:20]}")
>> "%CHECK_PY%" echo         else:
>> "%CHECK_PY%" echo             ok("Keine Drafts mit offensichtlichem >100/100 Score gefunden")
>> "%CHECK_PY%" echo except Exception as e:
>> "%CHECK_PY%" echo     fail(f"App/DB Fehler: {e}")
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo print("")
>> "%CHECK_PY%" echo print("=== PAGESPEED LIVE CHECK ===")
>> "%CHECK_PY%" echo key = os.getenv("PAGESPEED_API_KEY", "").strip()
>> "%CHECK_PY%" echo if not key:
>> "%CHECK_PY%" echo     warn("PAGESPEED_API_KEY fehlt - PageSpeed nutzt Fallback")
>> "%CHECK_PY%" echo else:
>> "%CHECK_PY%" echo     try:
>> "%CHECK_PY%" echo         r = requests.get("https://www.googleapis.com/pagespeedonline/v5/runPagespeed", params={"url":"https://example.com","strategy":"mobile","key":key}, timeout=25)
>> "%CHECK_PY%" echo         print("HTTP:", r.status_code)
>> "%CHECK_PY%" echo         if r.status_code == 200:
>> "%CHECK_PY%" echo             ok("PageSpeed API funktioniert")
>> "%CHECK_PY%" echo         else:
>> "%CHECK_PY%" echo             fail("PageSpeed API antwortet nicht mit 200")
>> "%CHECK_PY%" echo             print(r.text[:800])
>> "%CHECK_PY%" echo     except Exception as e:
>> "%CHECK_PY%" echo         fail(f"PageSpeed Test fehlgeschlagen: {e}")
>> "%CHECK_PY%" echo.
>> "%CHECK_PY%" echo print("")
>> "%CHECK_PY%" echo print("=== FAZIT ===")
>> "%CHECK_PY%" echo print("Wenn FEHLER oder WARNUNG erscheinen, ist das System noch nicht 100%% automationssicher.")

python "%CHECK_PY%"

echo.
echo ============================================================
echo  HEALTH CHECK BEENDET
echo ============================================================
echo.
pause
endlocal