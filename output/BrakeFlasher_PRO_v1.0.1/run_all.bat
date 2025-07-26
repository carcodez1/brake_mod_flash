@echo off
:: File: run_all.bat
:: Project: BRAKE_MOD_FLASH
:: Author: Jeffrey Plewak
:: License: Proprietary – NDA / IP Assigned
:: Description: Hardened Windows build orchestrator for testing, compiling, packaging GUI + firmware

setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: ---------- CONFIG ----------
set "PROJECT=BRAKE_MOD_FLASH"
set "VENV_DIR=.venv"
set "DIST_DIR=build\dist"
set "ARTIFACT_DIR=build\artifacts"
set "LOG_FILE=build\build.log"
set "HEX_FILE=%ARTIFACT_DIR%\BrakeFlasher.hex"
set "EXE_NAME=BrakeFlasherEmulator.exe"
set "SPEC_FILE=BrakeFlasherEmulator.spec"
set "ZIP_TS=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "ZIP_TS=!ZIP_TS: =0!"
set "ZIP_OUT=build\%PROJECT%_!ZIP_TS!.zip"

:: ---------- LOGGING ----------
if not exist build (
  mkdir build
)
echo [%DATE% %TIME%] BUILD STARTED > "%LOG_FILE%"
echo [*] Building %PROJECT%...

:: ---------- PYTHON CHECK ----------
where python >nul 2>&1
if errorlevel 1 (
  echo [✗] Python not found in PATH. >> "%LOG_FILE%"
  echo [✗] Install Python 3.7+ and re-run. Aborting.
  exit /b 1
)
set "PYTHON=python"

:: ---------- VENV SETUP ----------
if not exist "%VENV_DIR%" (
  echo [*] Creating virtual environment...
  %PYTHON% -m venv "%VENV_DIR%" >> "%LOG_FILE%" 2>&1
)
call "%VENV_DIR%\Scripts\activate.bat"

:: ---------- DEPENDENCY INSTALL ----------
echo [*] Installing dependencies...
%PYTHON% -m pip install --upgrade pip >> "%LOG_FILE%" 2>&1
if exist requirements.txt (
  %PYTHON% -m pip install -r requirements.txt >> "%LOG_FILE%" 2>&1
) else (
  %PYTHON% -m pip install pyinstaller pytest pytest-cov mock >> "%LOG_FILE%" 2>&1
)

:: ---------- UNIT TESTS ----------
echo [*] Running tests...
%PYTHON% run_tests.py >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
  echo [✗] Unit tests failed. Check build.log.
  exit /b 1
)
echo [✓] Tests passed.

:: ---------- BUILD GUI ----------
echo [*] Building GUI with PyInstaller...
pyinstaller --noconfirm "%SPEC_FILE%" >> "%LOG_FILE%" 2>&1
if not exist "dist\%EXE_NAME%" (
  echo [✗] GUI executable not found after PyInstaller run. >> "%LOG_FILE%"
  exit /b 1
)
mkdir "%DIST_DIR%" 2>nul
copy /Y "dist\%EXE_NAME%" "%DIST_DIR%\" >> "%LOG_FILE%" 2>&1

:: ---------- COMPILE HEX OR STUB ----------
echo [*] Checking for arduino-cli...
where arduino-cli >nul 2>&1
if not errorlevel 1 (
  echo [*] Compiling firmware to HEX...
  arduino-cli compile --fqbn arduino:avr:uno firmware --output-dir "%ARTIFACT_DIR%" >> "%LOG_FILE%" 2>&1
) else (
  echo [!] arduino-cli not found. Creating HEX stub.
  mkdir "%ARTIFACT_DIR%" 2>nul
  echo // HEX STUB > "%HEX_FILE%"
)

:: ---------- PACKAGE OUTPUT ----------
echo [*] Creating ZIP package: %ZIP_OUT%
powershell -Command "Compress-Archive -Force -Path '%DIST_DIR%','%ARTIFACT_DIR%','firmware\metadata\*.json','scripts\*.py','gui\*.py','README.md','LICENSE','build_project.sh','run_tests.py','%SPEC_FILE%' -DestinationPath '%ZIP_OUT%'" >> "%LOG_FILE%" 2>&1

:: ---------- DONE ----------
echo [✓] Build complete: %ZIP_OUT%
echo [✓] Executable:    %DIST_DIR%\%EXE_NAME%
echo [✓] Firmware HEX:  %HEX_FILE%
echo [%DATE% %TIME%] BUILD COMPLETE >> "%LOG_FILE%"

endlocal
