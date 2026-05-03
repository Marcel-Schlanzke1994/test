```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion
title AUTO-LEADS FULL INSTALLER

color 0A

echo =========================================================
echo               AUTO-LEADS WINDOWS INSTALLER
echo =========================================================
echo.
echo Dieses Setup installiert automatisch:
echo - Git (falls vorhanden wird es genutzt)
echo - Python 3.12 Empfehlung
echo - Virtual Environment
echo - Requirements
echo - .env Datei
echo - Datenbank Migration
echo - Start des lokalen Flask Dashboards
echo.
echo Projekt:
echo auto-leads
echo Repo:
echo https://github.com/Marcel-Schlanzke1994/auto-leads.git
echo =========================================================
echo.

set "PROJECT_DIR=%USERPROFILE%\auto-leads"
set "REPO_URL=https://github.com/Marcel-Schlanzke1994/auto-leads.git"

echo [1/8] Git-Pruefung...
where git >nul 2>nul
if errorlevel 1 (
    echo.
    echo FEHLER: Git ist nicht installiert.
    echo.
    echo Bitte zuerst Git installieren:
    echo https://git-scm.com/download/win
    echo.
    echo Danach diese BAT erneut starten.
    pause
    exit /b 1
)

echo Git gefunden.
echo.

echo [2/8] Python-Pruefung...
where py >nul 2>nul
if errorlevel 1 (
    echo.
    echo FEHLER: Python Launcher nicht gefunden.
    echo.
    echo Bitte Python 3.12 installieren:
    echo https://www.python.org/downloads/release/python-3120/
    echo.
    echo WICHTIG:
    echo [X] Add python.exe to PATH
    echo [X] pip installieren
    echo.
    echo Danach diese BAT erneut starten.
    pause
    exit /b 1
)

py -3.12 --version >nul 2>nul
if errorlevel 1 (
    echo.
    echo WARNUNG:
    echo Python 3.12 wurde nicht gefunden.
    echo Bitte Python 3.12 installieren.
    echo.
    echo Empfehlung:
    echo Keine Python 3.13 fuer dieses Projekt verwenden.
    echo.
    pause
    exit /b 1
)

echo Python 3.12 gefunden.
echo.

echo [3/8] Repository vorbereiten...

if not exist "%PROJECT_DIR%" (
    echo Klone Repository...
    git clone "%REPO_URL%" "%PROJECT_DIR%"
    if errorlevel 1 (
        echo FEHLER beim Klonen des Repositories.
        pause
        exit /b 1
    )
) else (
    echo Repository existiert bereits.
    echo Fuehre git pull aus...
    cd /d "%PROJECT_DIR%"
    git pull
)

cd /d "%PROJECT_DIR%"
echo.

echo [4/8] Alte virtuelle Umgebung entfernen...

if exist ".venv" (
    rmdir /s /q ".venv"
)

echo Erstelle neue virtuelle Umgebung...
py -3.12 -m venv .venv

if errorlevel 1 (
    echo FEHLER bei Erstellung der virtuellen Umgebung.
    pause
    exit /b 1
)

echo.

echo [5/8] Pip + Requirements installieren...

".venv\Scripts\python.exe" -m pip install --upgrade pip setuptools wheel

if errorlevel 1 (
    echo FEHLER bei pip Upgrade.
    pause
    exit /b 1
)

".venv\Scripts\python.exe" -m pip install -r requirements.txt

if errorlevel 1 (
    echo FEHLER bei requirements.txt Installation.
    pause
    exit /b 1
)

echo.

echo [6/8] .env Datei vorbereiten...

if not exist ".env" (
    if exist ".env.example" (
        copy ".env.example" ".env" >nul
        echo .env aus .env.example erstellt.
    ) else (
        echo FEHLER: Keine .env.example gefunden.
        pause
        exit /b 1
    )
) else (
    echo .env existiert bereits.
)

echo.
echo Bitte jetzt deinen GOOGLE_MAPS_API_KEY eintragen.
echo Die Datei wird automatisch geoeffnet.
echo.

notepad ".env"

echo.
echo Nach dem Speichern:
pause

echo.

echo [7/8] Datenbank Migration...

set FLASK_APP=run.py

".venv\Scripts\python.exe" -m flask db upgrade

if errorlevel 1 (
    echo FEHLER bei flask db upgrade.
    pause
    exit /b 1
)

echo Datenbank erfolgreich initialisiert.
echo.

echo [8/8] Starte Auto-Leads lokal...

echo Browser wird geoeffnet:
echo http://127.0.0.1:5000
echo.

start "" "http://127.0.0.1:5000"

echo Starte Flask Server...
echo.

".venv\Scripts\python.exe" run.py

echo.
echo =========================================================
echo Auto-Leads wurde beendet.
echo =========================================================
pause
```
